set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app fossilhub.tcl]

proc assertEqual {actual expected label} {
  if {$actual ne $expected} {
    puts stderr "$label: expected '$expected', got '$actual'"
    exit 1
  }
}

assertEqual [::fossilhub::routeForPath /] home "root route"
assertEqual [::fossilhub::routeForPath /explore] explore "explore route"
assertEqual [::fossilhub::routeForPath /repo/dig.fossil] \
  {repository dig.fossil} "repository route"
assertEqual [::fossilhub::routeForPath /healthz] health "health route"
assertEqual [::fossilhub::routeForPath /fh.css] stylesheet "stylesheet route"
assertEqual [::fossilhub::routeForPath /missing] not-found "not-found route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/explore] \
  explore "mounted explore route"

puts "route tests passed"

