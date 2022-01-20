using Project_Nested.Emulation;
using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class OptimizeGroup
    {
        #region Variables

        List<LinkOrigin> linkOrigins = new List<LinkOrigin>();
        List<MakeBinary> subroutines;

        List<int> calls;

        Injector injector;

        const string PROGRESS_COMPILE_NAME = "Compiling";
        const string PROGRESS_OPTIMIZE_NAME = "Optimizing";
        int progressMin;
        int progressMax;
        IProgress<Tuple<string, int, int>> progress;

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public OptimizeGroup(Injector injector, List<int> calls, byte staticRanges, IProgress<Tuple<string, int, int>> progress)
        {
            this.injector = injector;
            this.calls = calls;
            this.progress = progress;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Optimize

        public async Task OptimizeAllAsync(CancellationToken? ct)
        {
            progressMin = 0;
            var raw = new List<Task<Raw65816>>();
            foreach (var item in calls)
                raw.Add(RecompileAsync(ct, item));
            progressMax = raw.Count;
            await Task.WhenAll(raw);

            progressMin = 0;
            var optimized = new List<Task<MakeBinary>>();
            foreach (var item in raw)
                optimized.Add(OptimizeOneAsync(ct, item.Result));
            progressMax = optimized.Count;
            await Task.WhenAll(optimized);

            ct?.ThrowIfCancellationRequested();

            subroutines = optimized.Select(e => e.Result).ToList();
        }

        public void OptimizeAllSync()
        {
            subroutines = new List<MakeBinary>();
            foreach (var item in calls)
                subroutines.Add(OptimizeOneSync(null, RecompileSync(item)));
        }

        private async Task<MakeBinary> OptimizeOneAsync(CancellationToken? ct, Raw65816 code)
        {
            return await Task.Run(() => OptimizeOneSync(ct, code), ct.Value);
        }

        private MakeBinary OptimizeOneSync(CancellationToken? ct, Raw65816 code)
        {
            // Convert code to IL
            ct?.ThrowIfCancellationRequested();
            var il = code.ConvertToIL(injector);

            // Optimize
            var op = new OptimizeOperator(null, il);
            var il2 = op.Optimize(ct, false);

            // Convert to binary
            var bin = new MakeBinary(this, code.nesAddress, op.TimeOut ? il : il2, code.compileFlags, true);

            // Update progress
            IncrementProgress(PROGRESS_OPTIMIZE_NAME);

            // Debug report
            if (op.TimeOut)
                Debug.WriteLine($"Optimizing {code.nesAddress:x6} timed out.");
            else
                Debug.WriteLine($"Optimized {code.nesAddress:x6} in {op.iterationID} iterations.");

            // Return result
            return bin;
        }

        private void IncrementProgress(string name)
        {
            if (progress != null)
            {
                lock (progress)
                {
                    progressMin++;
                    if (progressMax > 0)
                    {
                        progress?.Report(new Tuple<string, int, int>(name, progressMin, progressMax));
                    }
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Finalize

        public void WriteLinks(c65816 emu)
        {
            var baseOrigin = injector.AddCallLinks(emu, linkOrigins);

            if (baseOrigin != 0)
                throw new Exception("Link origins were already initialized.");

            emu.AddFunctionCode(subroutines);
        }

        public void FixLinks(c65816 emu)
        {
            var memory = emu.memory;
            foreach (var item in subroutines)
            {
                var nesAddress = item.nesAddress;
                var snesAddress = item.snesAddress;
                var jumpSource = item.jumpSource;
                var staticCallSource = item.staticCallSource;
                var labels = item.labels;

                foreach (var jmp in jumpSource)
                {
                    var addr = snesAddress + jmp;
                    if (memory.DebugReadOneByte(addr - 1) != (byte)InstructionSet.JMP_Jmp16)
                        throw new Exception("Incorrect jump source.");

                    var labelNum = memory.DebugReadTwoByte(addr);
                    memory.DebugWriteTwoByte(addr, labels[labelNum] + snesAddress);
                }

                foreach (var call in staticCallSource)
                {
                    var addr = snesAddress + call;
                    var operand = memory.DebugReadThreeByte(addr);
                    var destinationAddr = injector.GetStaticBankDestination(nesAddress, operand);
                    if (destinationAddr < 0)
                        throw new Exception("Incorrect static NES call.");
                    destinationAddr = (destinationAddr << 16) + operand;
                    var destinationObj = subroutines.Find(e => e.nesAddress == destinationAddr);
                    memory.DebugWriteThreeByte(addr, destinationObj.snesAddress);
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Shared among tasks

        public int AddLinkOrigin(LinkOrigin origin)
        {
            lock (linkOrigins)
            {
                var index = linkOrigins.FindIndex(e => e.wholeData == origin.wholeData);
                if (!linkOrigins.Contains(origin))
                {
                    linkOrigins.Add(origin);
                    return linkOrigins.Count - 1;
                }
                else
                    return index;
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Recompile

        private Stack<c65816> emulatorPool = new Stack<c65816>();
        private object emuPoolCreateLocker = new object();

        private c65816 PullEmu()
        {
            // Safely pull emulator from stack
            lock (emulatorPool)
            {
                if (emulatorPool.Count > 0)
                    return emulatorPool.Pop();
            }

            // Stack is empty, create a new emulator
            c65816 emu = null;
            lock (emuPoolCreateLocker)
                // Create new emulator but initialize it after the lock
                emu = injector.NewEmulatorNoInit(null);
            emu.ExecuteInit(null);
            return emu;
        }

        private void PushEmu(c65816 emu)
        {
            // Safely push emulator to stack
            lock (emulatorPool)
            {
                emulatorPool.Push(emu);
            }
        }

        private async Task<Raw65816> RecompileAsync(CancellationToken? ct, int nesAddr)
        {
            return await Task.Run(() => RecompileSync(nesAddr), ct.Value);
        }

        private Raw65816 RecompileSync(int nesAddr)
        {
            // Borrow an emulator for this task
            var emu = PullEmu();

            var code = injector.RecompilerBuild(emu, nesAddr);

            PushEmu(emu);

            // Update progress
            IncrementProgress(PROGRESS_COMPILE_NAME);

            return code;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Link management

        /// <summary>
        /// Adds an open JIT link to AOT code.
        /// Returns the SNES address where the link is located.
        /// If the link already exists, it returns the existing link instead of adding a new link.
        /// </summary>
        /// <param name="originalReturn"></param>
        /// <param name="originalCall"></param>
        /// <returns></returns>
        public int AddCallLink(int originalReturn, int originalCall)
        {
            var link = new LinkOrigin(originalReturn, originalCall);
            int index = 0;
            lock (this)
            {
                index = linkOrigins.FindIndex(e => e == link);
                if (index < 0)
                {
                    index = linkOrigins.Count;
                    linkOrigins.Add(link);
                }
            }
            return 0x7f0000 + index * 4;
        }

        public LinkOrigin[] GetAllLinkOrigins() => linkOrigins.ToArray();

        #endregion
    }
}
