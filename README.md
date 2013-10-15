rack-mini-profiler
==================

This is a modified version of rack-mini-profiler.
It is based off the old 0.1.23 version as that works with Ruby 1.8.7
The native database SQL timing has been removed and only ActiveRecord left as we required support for multiple adapters which is only supported if you only use the ActiveRecord SQL timing.
