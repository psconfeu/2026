# prerequisites: ensure DSC and SSH Server are in the PATH

# get: see _inheritedDefaults
dsc config get -f .\0-demo.yml

# export: see only explicit settings
dsc config export -f .\0-demo.yml

# export: see only filtered explicit settings
dsc config export -f .\1-demo_filter.yml

# export: save export to apply to another "machine"
dsc config export -f .\1-demo_filter.yml > export_demo.json

# set: apply exported configuration to another "machine"
dsc config set -f .\export_demo.json

# set: purge any existing settings and apply new ones
dsc config set -f .\2-demo_purge.yml

# set: add new subsystem(s) while preserving existing ones
# utilize _purge: false to remove existing subsystems
dsc config set -f .\3-demo_subsystemList.yml

# set: remove subsystem, if it exists
# utilize _exist: true to add/update a specific subsystem
dsc config set -f .\4-demo_subsystem.yml
