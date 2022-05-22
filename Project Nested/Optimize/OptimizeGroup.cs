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
        List<MakeBinary> binSubroutines;

        List<int> calls;

        Injector injector;

        EmulatorPool emuPool;

        bool nativeReturn;

        const string PROGRESS_COMPILE_NAME = "Compiling";
        const string PROGRESS_OPTIMIZE_NAME = "Optimizing";
        const string PROGRESS_INLINE_NAME = "Optimizing (inline)";
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
            var optimized = new List<Task<OptimizeOperator>>();
            foreach (var item in raw)
                optimized.Add(OptimizeOneAsync(ct, item.Result));
            progressMax = optimized.Count;
            await Task.WhenAll(optimized);

            ct?.ThrowIfCancellationRequested();

            binSubroutines = optimized.Select(e => ConvertToBinary(e.Result)).ToList();
        }

        public void OptimizeAllSync()
        {
            List<OptimizeOperator> optimizeSubroutines = new List<OptimizeOperator>();
            foreach (var item in calls)
                optimizeSubroutines.Add(OptimizeOneSync(null, RecompileSync(item)));

            // Inline (TODO: Fix it)
            //InlineAllSync(optimizeSubroutines);

            // Convert to binary
            binSubroutines = optimizeSubroutines.Select(e => ConvertToBinary(e)).ToList();
        }

        private async Task<OptimizeOperator> OptimizeOneAsync(CancellationToken? ct, Raw65816 code)
        {
            return await Task.Run(() => OptimizeOneSync(ct, code), ct.Value);
        }

        private OptimizeOperator OptimizeOneSync(CancellationToken? ct, Raw65816 code)
        {
            // Convert code to IL
            ct?.ThrowIfCancellationRequested();
            var il = code.ConvertToIL(injector);

            // Optimize
            var op = new OptimizeOperator(null, code, injector);
            op.Optimize(ct, false);

            // Mark returns
            op.MarkReturns(this, (byte)(code.nesAddress >> 16));

            // Build cache (optional)
            op.BuildCache();

            // Convert to binary
            var il2 = op.GetCode();

            // Update progress
            IncrementProgress(PROGRESS_OPTIMIZE_NAME);

            // Debug report
            if (op.TimeOut)
                Debug.WriteLine($"Optimizing {code.nesAddress:x6} timed out.");
            else
                Debug.WriteLine($"Optimized {code.nesAddress:x6} in {op.iterationID} iterations.");

            // Return result
            return op;
        }

        private void InlineAllSync(List<OptimizeOperator> optimizeSubroutines)
        {
            const int BYTE_COUNT_TOTAL_LIMIT = 576 * 1024;  // Limit for estimate
            const int BYTE_COUNT_TOTAL_MAX = 512 * 1024;    // Actual max for ending the tasks early
            const int BYTE_COUNT_BANK_LIMIT = 8 * 1024;     // Limit for estimate
            int byteCount = optimizeSubroutines.Sum(e => e.CountBytes());

            var hasInlineCandidates = optimizeSubroutines.Where(e => e.GetInlineCandidates().Count > 0).ToList();

            progressMin = 0;
            progressMax = hasInlineCandidates.Count;

            while (hasInlineCandidates.Count > 0 && byteCount < BYTE_COUNT_TOTAL_MAX)
            {
                for (int i = hasInlineCandidates.Count - 1; i >= 0; i--)    // Reversed loop because we are removing elements
                {
                    var op = hasInlineCandidates[i];
                    var validCandidates = false;
                    foreach (var item in op.GetInlineCandidates())
                    {
                        // Find target
                        var target = optimizeSubroutines.Find(e => e.nesAddress == item.callDestination);

                        // Is target inline able?
                        if (target != null && target.IsInlineAble())
                        {
                            validCandidates = true;

                            // Would inline push byte count over the limit?
                            if ((byteCount + target.CountBytes()) < BYTE_COUNT_TOTAL_LIMIT
                                && (op.CountBytes() + target.CountBytes()) < BYTE_COUNT_BANK_LIMIT)
                            {
                                op.Inline(item, target);
                                op.Optimize(null, false);
                                break;
                            }
                        }
                    }

                    // Were all candidates valid?
                    if (!validCandidates)
                    {
                        // Invalid, remove it and increment progress
                        hasInlineCandidates.RemoveAt(i);
                        IncrementProgress(PROGRESS_INLINE_NAME);
                    }
                }
            }
        }

        private MakeBinary ConvertToBinary(OptimizeOperator op)
        {
            return new MakeBinary(this, op.nesAddress, op.GetCode(), op.compileFlags, nativeReturn);
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

            emu.AddFunctionCode(binSubroutines);
        }

        public void FixLinks(c65816 emu)
        {
            if (baseLinkOrigin == 0 && (linkOrigins.Count != 0 || returnMarkers.Count != 0))
                throw new Exception("Link origins aren't initialized.");

            var memory = emu.memory;
            foreach (var item in binSubroutines)
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
                    var destinationObj = binSubroutines.Find(e => e.nesAddress == destinationAddr);
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
