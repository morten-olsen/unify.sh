# Unify.sh

Simple bash script to setup a JBOD storage array with write-to-cache and parity.

## Setup

Start by creating a folder. Throughout this guide we will use `/nas` as an example, but you can
replace it with whatever you feel like (you need write access).

First start by mounting or linking your data disks at `/nas/unify/{some-name}`. That's it, the
simplest of setup. Now just run `unify.sh setup_fs /nas` and the disks are unified at
`/nas/joined`.

When ever you add files to `/nas/joined` they will be written to your current write disk. To see a
list of disks and their index run `unify.sh list_unions /nas`. To see which disk is your current
write disk run `unify.sh get_write /nas` and to change it run `unify.sh set_write /nas <INDEX>`,
where index is the index from `list_unions`

There are not automatic write switching so you will have to provide your own mechanism for swapping
between disks based on your strategy (manual or nightly cron are accepted answers).

### Write-to-cache

To improve performance you can use write-to-cache where all file writes are written to a cache layer
usually with a high performance storage tier. To enable this simply mount your cache drive to
`/nas/cache` and run `unify.sh setup_fs /nas` and it will be enabled.

To flush the cache from the cache drive to the regular storage drive (as specified by the
`get_write` command) you need to run `unify.sh flush_cache /nas`. Again no automation here so you
need to set up you own tasks to flush (manual or nightly cron are accepted answers).

### Parity

It supports [SnapRAID](https://www.snapraid.it/), which isn't a real RAID but does offer some ofthe
functionality, but you should familiarize youself with it, and its limitations and advantages before
using it.

Mount (or link) you parity disk to `/nas/parity`

To run SnapRAID commands you can use `unify.sh raid /nas <your snapraid command>`, so to do a
snapraid sync you run `unify.sh raid /nas sync`.
