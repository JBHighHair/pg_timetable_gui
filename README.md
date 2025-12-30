# pg_timetable_gui: IDE for [pg_timetable](https://github.com/cybertec-postgresql/pg_timetable) scheduler

**pg_timetable_gui** is a free cross-platform tool for administrators who need to work with the advanced PostgreSQL [pg_timetable](https://github.com/cybertec-postgresql/pg_timetable) scheduler.

**pg_timetable_gui** is a re-write of https://github.com/cybertec-postgresql/pg_timetable_gui

![pg_timetable_gui main window](res/Screenshot1.png)
![pg_timetable_gui main window](res/Screenshot2.png)
![pg_timetable_gui main window](res/Screenshot3.png)

## Features
- Create/update/delete chains and tasks
- Change task order
- Supports user and LDAP logins
- Syntax highlighting of SQL, command line and JSON parameters
- Displays execultion log and duration
- Supports all BUILTIN commands as of pg_timetable 6.2.0

## Requirements
Working pg_timetable scheduler version 6.2.0 and above running on PostgreSQL.

## Compling pg_timetable_gui
You will require Lazarus https://www.lazarus-ide.org/ to compile the binary.

No extra packages are required.


The source code has been compiled and tested for the following environments:
- Windows 11 \ Windows Server 2019
- Fedora Workstation 43

## Support
Description of chain and task properties can be found here https://cybertec-postgresql.github.io/pg_timetable

## Credits
- Portions of code copied from original author [Pavlo Golub](https://github.com/pashagolub)
   * UpdateCronTimes
   * IsCronValueValid
   * SelectSQL 
- Media: open-source [RemixIcons](https://remixicon.com/) set
