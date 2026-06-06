Add-Type -OutputType ConsoleApplication -OutputAssembly win_argv.exe -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace PrintArgv
{
    class Program
    {
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetCommandLineW();

        static void Main(string[] args)
        {
            IntPtr cmdLinePtr = GetCommandLineW();
            string cmdLine = Marshal.PtrToStringUni(cmdLinePtr);

            Console.WriteLine(cmdLine);
            for (int i = 0; i < args.Length; i++)
            {
                Console.WriteLine("[{0}] {1}", i, args[i]);
            }
        }
    }
}
'@