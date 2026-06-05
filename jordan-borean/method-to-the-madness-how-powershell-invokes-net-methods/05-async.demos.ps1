Info {
    Title "Async Methods"

    Introduction "Learn to call async methods, await tasks, and handle task results properly in PowerShell."

    KeyConcepts @(
        "Calling async methods returns Task objects"
        "Awaiting co-operatively with AsyncWaitHandle or PipelineStopToken"
        "Using .GetResult() instead of .Result to ensure exceptions are seen"
        "Delegates fail when being set as a ScriptBlock, use .NET compiled methods"
    )

    $awaitExample = @'
$task = [Task]::Delay(1000)
while (-not $task.AsyncWaitHandle.WaitOne(300)) {}
$task.GetAwaiter().GetResult()
'@ | Format-PowerShell

    $awaitStopTokenExample = @'
[CmdletBinding()]
param()

$task = [Task]::Delay(1000, $PSCmdlet.PipelineStopToken)
$task.GetAwaiter().GetResult()
'@ | Format-PowerShell

    Summary @"
Async methods return immediately with a Task. Wait for completion with .GetAwaiter().GetResult():

$awaitExample

PowerShell 7.6+ adds PipelineStopToken for easier cancellation support in cmdlets/advanced function:

$awaitStopTokenExample

Never use .Result - it swallows exceptions in PowerShell.
"@

    CommonPitfalls @"
• Using .Result instead of .GetAwaiter().GetResult()
• Not waiting for tasks to complete
• Expecting ScriptBlock delegates to just work
"@
}

Demo "Calling async method" {
    Description "Shows how calling an async method will run the task in the background"

    Code {
        Measure-Command {
            [System.Threading.Tasks.Task]::Delay(5000)
        }
    }
}

Demo "Awaiting async methods" {
    Description "Shows how to call an async method with explicit wait using AsyncWaitHandle"

    Code {
        Measure-Command {
            $task = [System.Threading.Tasks.Task]::Delay(3000)

            # Allows us to stop the pipeline with ctrl+c
            while (-not $task.AsyncWaitHandle.WaitOne(300)) {}

            # Get's the result from the task. Will be void/null here.
            $task.GetAwaiter().GetResult()
        }
    }
}

Demo "PipelineStopToken (7.6+)" {
    Description "Shows how to use PipelineStopToken for a more efficient and easier wait in PowerShell 7.6+"

    Code {
        Measure-Command {
            &{
                [CmdletBinding()]
                param()

                $task = [System.Threading.Tasks.Task]::Delay(
                    3000,
                    $PSCmdlet.PipelineStopToken)
                $task.GetAwaiter().GetResult()
            }
        }
    }
}

Demo ".GetResult() vs .Result" {
    Description "Shows why .GetResult() should be used instead of .Result - it ensures exceptions are thrown and not ignored in PowerShell"

    Code {
        Add-Type -TypeDefinition @'
        using System;
        using System.Threading.Tasks;

        public class TaskWithException
        {
            public static async Task Run()
            {
                await Task.Delay(0);
                throw new Exception("exception in task");
            }
        }
'@

        $task = [TaskWithException]::Run()

        "Testing with .Result"
        $task.GetAwaiter().Result

        "Testing with .GetResult()"
        $task.GetAwaiter().GetResult()
    }
}

Demo "ScriptBlock delegate in async task" {
    Description "Shows how using a ScriptBlock as a delegate in an async task will fail"

    Code {
        $task = [System.Threading.Tasks.Task]::Run([Action]{'boo'})
        $task.GetAwaiter().GetResult()
    }
}

Demo "ScriptBlock delegate with explicit Runspace" {
    Description "Shows how you can still use a ScriptBlock delegate with a wrapper"

    Code {
        Add-Type -TypeDefinition @'
        using System.Management.Automation;
        using System.Management.Automation.Runspaces;
        using System.Threading.Tasks;

        public class AsyncScriptBlock<T>
        {
            private readonly ScriptBlock _sbk;

            public AsyncScriptBlock(ScriptBlock sbk)
            {
                _sbk = sbk;
            }

            public T Invoke()
            {
                using Runspace runspace = RunspaceFactory.CreateRunspace();
                runspace.Open();

                using PowerShell ps = PowerShell.Create(runspace);
                ps.AddScript("& $args[0].Ast.GetScriptBlock()").AddArgument(_sbk);
                var output = ps.Invoke();

                return output.Count > 0
                    ? LanguagePrimitives.ConvertTo<T>(output[0])
                    : (T)default;
            }
        }
'@

        $wrapper = [AsyncScriptBlock[string]]::new({"from scriptblock"})
        $task = [System.Threading.Tasks.Task]::Run([Func[string]]$wrapper.Invoke)
        $task.GetAwaiter().GetResult()
    }
}
