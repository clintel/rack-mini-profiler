# rack-mini-profiler

This is a modified version of rack-mini-profiler.
It is based off 2.3.1 version as that works with Ruby 2.5.8
The native database SQL timing has been removed and only ActiveRecord left as we required support for multiple adapters which is only supported if you only use the ActiveRecord SQL timing.


