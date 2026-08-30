set projectRoot [file dirname [file dirname [file normalize [info script]]]]
source [file join $projectRoot app lib i18n.tcl]

proc fail {message} {
  puts stderr $message
  exit 1
}

proc assertEqual {actual expected label} {
  if {$actual ne $expected} {
    fail "$label: expected '$expected', got '$actual'"
  }
}

assertEqual [::fossilhub::i18n::normalize zh] zh-CN \
  "Chinese language normalization"
assertEqual [::fossilhub::i18n::normalize zh-Hans-CN] zh-CN \
  "Chinese region normalization"
assertEqual [::fossilhub::i18n::normalize en-US] en \
  "English language normalization"
assertEqual [::fossilhub::i18n::normalize fr] "" \
  "unsupported language rejected"

assertEqual [::fossilhub::i18n::fromSources \
  {theme=dark; fh_locale=zh-CN; session=opaque} en-US] zh-CN \
  "language Cookie takes precedence"
assertEqual [::fossilhub::i18n::fromSources {} {fr-FR, zh-Hans;q=0.9, en;q=0.8}] \
  zh-CN "browser language fallback"
assertEqual [::fossilhub::i18n::fromSources {} {fr-FR}] en \
  "English final fallback"

assertEqual [::fossilhub::i18n::returnTo \
  {/bemly-moe/app/fossilhub/repo/bedrock.fossil?tab=files#top}] \
  {/bemly-moe/app/fossilhub/repo/bedrock.fossil?tab=files#top} \
  "mounted return path accepted"
foreach unsafe [list {//example.test/path} {/safe\path} \
    {https://example.test/} "/safe\nSet-Cookie: bad=1"] {
  assertEqual [::fossilhub::i18n::returnTo $unsafe] / \
    "unsafe return path rejected"
}

::fossilhub::i18n::use zh-CN
assertEqual [::fossilhub::i18n::t sign_in] 登录 \
  "Chinese translation selected"
assertEqual [::fossilhub::i18n::t missing_key] missing_key \
  "missing translation has safe key fallback"
::fossilhub::i18n::use en
assertEqual [::fossilhub::i18n::t sign_in] {Sign in} \
  "English translation selected"

puts "i18n tests passed"
