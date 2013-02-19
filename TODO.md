NOW
- [ ] use an NSError with -[AMSerialPort open]
- [ ] use an NSError with -[AMSerialPort commitChanges]

LATER
- [ ] investigate phantom newline-only data
- [ ] investigate phantom issue with runaway kernel task / hang maxing out a core on replug, seems like a race condition, try to open as the system brings the port up
- [ ] open ports for only read or only write O_RDONLY, O_WRONLY
