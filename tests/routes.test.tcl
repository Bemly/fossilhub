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
assertEqual [::fossilhub::routeForPath /explore.html] explore "legacy explore route"
assertEqual [::fossilhub::routeForPath /repo/dig.fossil] \
  {repository dig.fossil timeline} "repository route"
assertEqual [::fossilhub::routeForPath /repo.html] \
  {repository sqlite.fossil timeline} "legacy repository route"
assertEqual [::fossilhub::routeForPath /catalog-fragment] \
  catalog-fragment "catalog fragment route"
assertEqual [::fossilhub::routeForPath /healthz] health "health route"
assertEqual [::fossilhub::routeForPath /fh.css] stylesheet "stylesheet route"
assertEqual [::fossilhub::routeForPath /fossilhub-live.js] \
  live-script "live integration script route"
assertEqual [::fossilhub::routeForPath /repo/fossilhub-live.js] \
  live-script "nested live integration script route"
assertEqual [::fossilhub::routeForPath /repo/catalog-search.js] \
  catalog-script "nested catalog script route"
assertEqual [::fossilhub::routeForPath /missing] not-found "not-found route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/explore] \
  explore "mounted explore route"
assertEqual [::fossilhub::routeForPath /bemly-moe/app/fossilhub/] \
  home "mounted home route"

puts "route tests passed"
