using Project_Nested.Emulation;
using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Project_Nested
{
    class AutoPlay
    {
        Injector injector;

        const string PROGRESS_AUTOPLAY_NAME = "Auto-play";
        int progressMin;
        int progressMax;
        IProgress<Tuple<string, int, int>> progress;

        EmulatorPool emuPool;

        List<int> feedback;

        public AutoPlay(Injector injector, IProgress<Tuple<string, int, int>> progress)
        {
            this.injector = injector;
            this.emuPool = new EmulatorPool(injector.GetOutData(), false);
            this.progress = progress;
        }

        // --------------------------------------------------------------------

        public async Task<List<int>> PlayAsync(CancellationToken? ct)
        {
            Func<c65816, int>[] playSessions = MakePlaySessions();

            progressMin = -1;
            IncrementProgress(PROGRESS_AUTOPLAY_NAME);
            var plays = new List<Task<List<int>>>();
            foreach (var session in playSessions)
                plays.Add(PlayOneAsync(ct, session));
            progressMax = plays.Count;
            await Task.WhenAll(plays);

            var plays2 = plays.Select(e => e.Result).ToList();
            plays2.Add(injector.GetAllKnownCalls().ToList());

            return MergeLists(plays2);
        }

        public List<int> PlaySync()
        {
            Func<c65816, int>[] playSessions = MakePlaySessions();

            var plays = new List<List<int>>();
            foreach (var session in playSessions)
                plays.Add(PlayOneSync(null, session));

            plays.Add(injector.GetAllKnownCalls().ToList());

            return MergeLists(plays);
        }

        // --------------------------------------------------------------------

        private List<int> MergeLists(List<List<int>> lists)
        {
            List<int> rtn = new List<int>();

            foreach (var list in lists)
            {
                if (list != null)
                {
                    foreach (var item in list)
                    {
                        if (!rtn.Contains(item))
                            rtn.Add(item);
                    }
                }
            }

            return rtn;
        }

        // --------------------------------------------------------------------

        private async Task<List<int>> PlayOneAsync(CancellationToken? ct, Func<c65816, int> playSession)
        {
            return await Task.Run(() => PlayOneSync(ct, playSession), ct.Value);
        }

        private List<int> PlayOneSync(CancellationToken? ct, Func<c65816, int> playSession)
        {
            // Get new emulator and reset it
            var emu = emuPool.PullEmu();
            emu.memory.DebugWriteRom = false;
            emu.InterruptReset();
            emu.memory.io.irqEnabled = false;

#if !DEBUG
            try
#endif
            {
                const int INITIAL_FRAME_COUNT = 60 * 30;        // 30 seconds
                const int CYCLES_PER_FRAME = 1000000 / 60;      // Cycles are not accurate and only counted per opcode read (except MVP and MVN)
                int feedbackCount = 0;
                for (int frameCount = INITIAL_FRAME_COUNT; frameCount >= 0; frameCount--)
                {
                    // Update controller input
                    emu.memory.io.input1 = playSession(emu);

                    // Execute for roughly 1 frame
                    emu.ExecuteSteps(CYCLES_PER_FRAME);

                    // Interrupt
                    if (emu.memory.io.irqEnabled)
                    {
                        emu.setflag_r(-1);
                        emu.InterruptIRQ();
                    }

                    // Has feedback count changed since the previous frame?
                    if (emu.feedback != null && emu.feedback.Count > feedbackCount)
                    {
                        feedbackCount = emu.feedback.Count;
                        frameCount = INITIAL_FRAME_COUNT;       // Reset session timeout
                    }
                }
            }
#if !DEBUG
            catch (Exception)
            {
                // Ignore error in release mode for now
            }
#endif

            // Take feedback and remove it before pushing emulator back to the stack
            var feedback = emu.feedback;
            emu.feedback = null;
            emuPool.PushEmu(emu);

            // Update progress
            IncrementProgress(PROGRESS_AUTOPLAY_NAME);

            return feedback;
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

        // --------------------------------------------------------------------

        private Func<c65816, int>[] MakePlaySessions()
        {
            return new Func<c65816, int>[]
            {
                Session_Idle(),
                Session_StartA(),
                Session_Random(),
            };
        }

        // --------------------------------------------------------------------

        private Func<c65816, int> Session_Idle()
        {
            return (emu) =>
            {
                return 0;
            };
        }

        private Func<c65816, int> Session_StartA()
        {
            int cycle = 0;
            int[] inputList = new int[] { 0, 0x8000, 0, 0x1000 };

            return (emu) =>
            {
                // Alternate between pressing Start and A
                return inputList[((cycle++) / 4) % inputList.Length];
            };
        }

        private Func<c65816, int> Session_Random()
        {
            Random random = new Random();

            return (emu) =>
            {
                return (1 << random.Next(0, 16)) & 0xfff0;
            };
        }
    }
}
