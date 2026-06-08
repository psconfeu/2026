# Instructor Notes

recap workshop 1 -> give small assignment to make a single test for simple function -> 15 minutes  
go on to test function -> first manual list of multiple tests

* data driven -> hashtable manually
  * -> import json -> array  
  * -> using templates with subproperties -> 25 minutes

mocking -> substitute function/stabilize function --> include parameter filter/default catch  
broken test -> always returns actual time until session [refactor get-pcsesession to include "timeuntilsession" based on Get-Date] -> stabilize  
mock get data -> substitutes a function  
guard mock to prevent accidental changes/breaks -> throw exception  
mock post data against 'live' endpoint (should-invoke to validate it called function with correct data)  
integration test -> bridge to containerized tests

condition docker available or not => have local start-server use pester test-drive to access json files

end2end tests -> tag tests -> use pester configuration  
flaky tag -> exclude in pester configuration
