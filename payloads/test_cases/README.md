
### Test Payloads

1. `sigsegv_crash_trigger.lua` - Triggers two SIGSEGV crashes in succession that should be signal handled without crashing the game process.
2. `notification_popup.lua` - Triggers a notification popup with 'Hello World' on the PlayStation.
3. `sigbus_crash_trigger.lua` - Triggers a SIGBUS crash that should be signal handled without crashing the game process.
4. `streaming_output.lua` - Prints basic information and trigger two SIGSEGV crashes in the middle, to demonstrate how streaming real-time output works.
5. `threading_test.lua` - Provides examples on how to run lua code in new threads.
