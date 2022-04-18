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
        List<int> returnMarkers = new List<int>();
        List<MakeBinary> subroutines;

        List<int> calls;

        Injector injector;

        EmulatorPool emuPool;

        bool nativeReturn;

        const string PROGRESS_COMPILE_NAME = "Compiling";
        const string PROGRESS_OPTIMIZE_NAME = "Optimizing";
        int progressMin;
        int progressMax;
        IProgress<Tuple<string, int, int>> progress;

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public OptimizeGroup(Injector injector, List<int> calls, byte staticRanges, bool nativeReturn, IProgress<Tuple<string, int, int>> progress)
        {
            this.injector = injector;
            this.emuPool = new EmulatorPool(injector.GetOutData(), true);
            this.calls = calls.Where(e => (e & 0xffff) >= 0x8000).ToList();
            this.nativeReturn = nativeReturn;
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
            op.Optimize(ct, false);

            // Mark returns
            op.MarkReturns(this, (byte)(code.nesAddress >> 16));

            // Convert to binary
            var il2 = op.GetCode();
            var bin = new MakeBinary(this, code.nesAddress, op.TimeOut ? il : il2, code.compileFlags, nativeReturn);

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
                    if (progressMax >= 0)
                    {
                        progress?.Report(new Tuple<string, int, int>(name, progressMin, progressMax));
                    }
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Finalize

        private int baseLinkOrigin;
        public void WriteLinks(c65816 emu)
        {
            baseLinkOrigin = injector.AddCallLinks(emu, linkOrigins);

            if ((baseLinkOrigin & 0xffff) != 0)
                throw new Exception("Link origins were already initialized.");

            emu.AddFunctionCode(subroutines);
        }

        public void FixLinks(c65816 emu)
        {
            if (baseLinkOrigin == 0 && (linkOrigins.Count != 0 || returnMarkers.Count != 0))
                throw new Exception("Link origins aren't initialized.");

            var memory = emu.memory;
            foreach (var item in subroutines)
            {
                var nesAddress = item.nesAddress;
                var snesAddress = item.snesAddress;
                var jumpSource = item.jumpSource;
                var staticCallSource = item.staticCallSource;
                var labels = item.labels;
                var returnMarkers = item.returnMarkers;

                if (snesAddress == 0)
                    continue;

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

                foreach (var mark in returnMarkers)
                {
                    var index = linkOrigins.FindIndex(e => e.fullRtn == mark.Key);
                    if (index < 0)
                        throw new Exception("Invalid return marker.");
                    var addr = baseLinkOrigin + 0x10000 + index * 4;

                    memory.DebugWriteFourByte(addr, mark.Value + snesAddress);
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Recompile

        private async Task<Raw65816> RecompileAsync(CancellationToken? ct, int nesAddr)
        {
            return await Task.Run(() => RecompileSync(nesAddr), ct.Value);
        }

        private Raw65816 RecompileSync(int nesAddr)
        {
            // Borrow an emulator for this task
            var emu = emuPool.PullEmu();

            var code = injector.RecompilerBuild(emu, nesAddr);

            emuPool.PushEmu(emu);

            // Update progress
            IncrementProgress(PROGRESS_COMPILE_NAME);

            return code;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Link management

        /// <summary>
        /// Add return marker and returns true when it's new.
        /// </summary>
        /// <param name="nesReturn"></param>
        /// <returns></returns>
        public bool AddReturnMarker(int nesReturn)
        {
            lock (returnMarkers)
            {
                var index = returnMarkers.FindIndex(e => e == nesReturn);
                if (index < 0)
                {
                    returnMarkers.Add(nesReturn);
                    return true;
                }
                else
                    return false;
            }
        }

        public int AddLinkOrigin(LinkOrigin origin)
        {
            lock (linkOrigins)
            {
                var index = linkOrigins.FindIndex(e => e == origin);
                if (index < 0)
                {
                    linkOrigins.Add(origin);
                    return linkOrigins.Count - 1;
                }
                else
                    return index;
            }
        }

        public LinkOrigin[] GetAllLinkOrigins() => linkOrigins.ToArray();

        #endregion
    }
}
