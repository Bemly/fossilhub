namespace eval ::fossilhub::i18n {
  variable activeLocale en
  variable supported {en zh-CN}
  variable messages [dict create \
    en [dict create \
      explore Explore \
      sign_in {Sign in} \
      register {Create account} \
      dashboard Dashboard \
      repositories {My repositories} \
      new_repository {New repository} \
      profile Profile \
      settings Settings \
      admin Admin \
      sign_out {Sign out} \
      switch_language 中文 \
      locale_label Language \
      account_navigation {Account navigation} \
      primary_navigation {Primary navigation} \
      repository_navigation {Repository navigation} \
      theme_toggle {Toggle color theme} \
      maintenance_notice {Maintenance notice} \
      identity {Identity} \
      access Access \
      audit Audit \
      username_or_email {Username or email} \
      username Username \
      display_name {Display name} \
      email Email \
      password Password \
      confirm_password {Confirm password} \
      create_account {Create account} \
      already_registered {Already registered?} \
      new_to_dig {New to this dig?} \
      return_to_field {Return to the field} \
      account_opens_tools {Your account opens the repositories and tools assigned to you.} \
      claim_survey_mark {Claim your survey mark} \
      identity_follows_work {One identity follows every commit, field note, ticket, and discussion.} \
      password_help {At least 12 characters. Passwords are stored with Argon2id.} \
      timeline Timeline \
      files Files \
      wiki Wiki \
      tickets Tickets \
      forum Forum \
      engine Engine \
      featured Featured \
      surface_feed {Surface feed} \
      all_digs {All digs} \
      home_title {FossilHub — The whole project, preserved in one stone} \
      home_eyebrow {FossilHub · A home for Fossil repositories} \
      home_heading {The whole project, preserved in one <em>stone.</em>} \
      home_lede {Fossil keeps code, wiki, tickets, forum, and docs inside a single versioned artifact. Open it in a browser tab or clone it to work offline — either way, you hold the entire history of the dig.} \
      explore_repositories {Explore repositories} \
      field_manual {Read the field manual} \
      explore_title {Explore digs — FossilHub} \
      explore_eyebrow {FossilHub · Site survey} \
      explore_heading {The field guide to open digs.} \
      explore_lede {Every listing below is a complete Fossil repository — code, wiki, tickets, and forum packed into one artifact you can clone, mirror, or mail. Sorted by most recent surface activity.} \
      search_repositories {Search repositories} \
      search_placeholder {Search names, descriptions, categories, or languages} \
      strata Strata \
      all All \
      code Code \
      sort Sort \
      recent_activity {Recent activity} \
      oldest_first {Oldest first} \
      name_az {Name A–Z} \
      largest_first {Largest first} \
      apply_filters {Apply filters} \
      no_matches {No repositories match this survey.} \
      broader_search {Try a broader term or select a different stratum.} \
      surface_specimen {Surface specimen} \
      matching_digs {Across matching digs — the surface feed} \
      scroll_hint {scroll →} \
      survey_results {Survey results} \
      indexed_sqlite {INDEXED IN SQLITE} \
      showing SHOWING] \
    zh-CN [dict create \
      explore 探索 \
      sign_in 登录 \
      register 注册 \
      dashboard 工作台 \
      repositories {我的仓库} \
      new_repository {新建仓库} \
      profile {个人主页} \
      settings 设置 \
      admin 管理 \
      sign_out 退出 \
      switch_language English \
      locale_label 语言 \
      account_navigation {账户导航} \
      primary_navigation 主导航 \
      repository_navigation 仓库导航 \
      theme_toggle {切换配色主题} \
      maintenance_notice {维护通知} \
      identity 身份 \
      access 权限 \
      audit 审计 \
      username_or_email {用户名或邮箱} \
      username 用户名 \
      display_name {显示名称} \
      email 邮箱 \
      password 密码 \
      confirm_password {确认密码} \
      create_account {创建账户} \
      already_registered {已经注册？} \
      new_to_dig {第一次来到这里？} \
      return_to_field {返回工作现场} \
      account_opens_tools {登录后即可使用分配给你的仓库和工具。} \
      claim_survey_mark {建立你的勘探标记} \
      identity_follows_work {一个身份贯穿每次提交、现场记录、Ticket 和讨论。} \
      password_help {密码至少为十二个字符，并使用 Argon2id 保存。} \
      timeline 时间线 \
      files 文件 \
      wiki Wiki \
      tickets Tickets \
      forum 论坛 \
      engine 原理 \
      featured 精选 \
      surface_feed {地表动态} \
      all_digs {全部仓库} \
      home_title {FossilHub — 将整个项目凝结在一块岩石中} \
      home_eyebrow {FossilHub · Fossil 仓库的家} \
      home_heading {整个项目，凝结在一块<em>岩石</em>中。} \
      home_lede {Fossil 将代码、Wiki、Tickets、论坛和文档保存在一个带版本历史的 artifact 中。你可以直接在浏览器中查看，也可以克隆到本地离线工作；无论哪种方式，完整的项目历史都在手中。} \
      explore_repositories {探索仓库} \
      field_manual {阅读现场手册} \
      explore_title {探索仓库 — FossilHub} \
      explore_eyebrow {FossilHub · 站点勘测} \
      explore_heading {开放仓库的现场指南。} \
      explore_lede {下面每一项都是完整的 Fossil 仓库：代码、Wiki、Tickets 和论坛收纳在一个可克隆、镜像或传递的 artifact 中，并按最近活动排序。} \
      search_repositories {搜索仓库} \
      search_placeholder {按名称、描述、分类或语言搜索} \
      strata 地层 \
      all 全部 \
      code 代码 \
      sort 排序 \
      recent_activity {最近活动} \
      oldest_first {最早优先} \
      name_az {名称 A–Z} \
      largest_first {最大优先} \
      apply_filters {应用筛选} \
      no_matches {没有仓库符合当前勘测条件。} \
      broader_search {请尝试更宽泛的关键词或选择其他地层。} \
      surface_specimen {地表标本} \
      matching_digs {符合条件仓库的地表动态} \
      scroll_hint {滚动 →} \
      survey_results {勘测结果} \
      indexed_sqlite {已索引至 SQLite} \
      showing 显示]]
  variable phrases [dict create zh-CN [dict create \
    Dashboard 工作台 \
    {Field workspace} {现场工作区} \
    {Survey your work} {勘测你的工作} \
    {Repositories, open work, and recent changes gathered in one place.} \
      {在一处查看仓库、待办事项和最近变更。} \
    {Public field record} {公开现场记录} \
    {A public identity, repository record, and activity summary.} \
      {展示公开身份、仓库记录和活动摘要。} \
    {Account settings} {账户设置} \
    {Identity · preferences} {身份 · 偏好} \
    {Shape your field record} {整理你的现场记录} \
    {Manage the public details and local appearance attached to your account.} \
      {管理账户的公开资料和本机界面外观。} \
    {Identity checkpoint} {身份检查点} \
    {Open a field record} {建立现场记录} \
    {Account security} {账户安全} \
    {Identity · security} {身份 · 安全} \
    {Secure your field record} {保护你的现场记录} \
    {Change your credential and close sessions you no longer recognize.} \
      {修改凭据并关闭不再认可的登录会话。} \
    {Repository workspace} {仓库工作区} \
    {Workspace · repositories} {工作区 · 仓库} \
    {Your working strata} {你的工作地层} \
    {Create, inspect, and manage the repositories entrusted to your account.} \
      {创建、查看并管理交由你账户保管的仓库。} \
    {New repository} {新建仓库} \
    {Workspace · deposition} {工作区 · 沉积} \
    {Open a new stratum} {开辟新地层} \
    {FossilHub initializes an isolated Fossil repository and records you as its owner.} \
      {FossilHub 会初始化独立的 Fossil 仓库，并将你记录为所有者。} \
    {Repository settings} {仓库设置} \
    {Workspace · custody} {工作区 · 保管} \
    {Manage this stratum} {管理此地层} \
    {Visibility, collaborators, ownership, and archive state are enforced centrally.} \
      {可见性、协作者、所有权和归档状态由平台统一执行。} \
    {Platform custody} {平台保管} \
    Overview 概览 \
    Users 用户 \
    Repositories 仓库 \
    Audit 审计 \
    Health 健康 \
    Settings 设置 \
    {Administrator overview} {管理员概览} \
    {Hold the whole survey} {掌握全局勘测} \
    {Platform counts, custody signals, and recent audited change.} \
      {查看平台统计、保管信号和近期审计变更。} \
    {Administrator users} {管理员 · 用户} \
    {Inspect identities} {检查身份} \
    {Every account action is attributable and reversible.} \
      {每项账户操作都可追溯、可回退。} \
    {Administrator user record} {管理员 · 用户记录} \
    {Review access, repository relationships, and active sessions.} \
      {检查访问权限、仓库关系和活动会话。} \
    {Administrator repositories} {管理员 · 仓库} \
    {Repository custody} {仓库保管} \
    {Inspect every registered stratum without exposing its contents.} \
      {在不暴露内容的前提下检查每个已注册地层。} \
    {Administrator repository record} {管理员 · 仓库记录} \
    {Visibility, ownership, lifecycle, and integrity controls.} \
      {检查可见性、所有权、生命周期和完整性控制。} \
    {Administrator audit} {管理员 · 审计} \
    {Audit ledger} {审计账本} \
    {Search and export a deliberately redacted operational record.} \
      {搜索并导出经过刻意脱敏的运维记录。} \
    {Administrator health} {管理员 · 健康} \
    {Platform health} {平台健康} \
    {Integrity, freshness, readability, modes, and release identity.} \
      {检查完整性、新鲜度、可读性、权限模式和发布标识。} \
    {Administrator settings} {管理员 · 设置} \
    {Platform policy} {平台策略} \
    {Registration, defaults, limits, and public maintenance notice.} \
      {管理注册、默认值、限制和公开维护通知。} \
    {Administrator verification} {管理员验证} \
    {Confirm administrator custody} {确认管理员身份} \
    {Your password is verified locally and is never retained in the audit ledger.} \
      {密码只在本地验证，绝不会保留在审计账本中。}]]
}

proc ::fossilhub::i18n::normalize {value} {
  set value [string map {_ -} [string trim $value]]
  if {[regexp -nocase {^zh(?:-|$)} $value]} {
    return zh-CN
  }
  if {[regexp -nocase {^en(?:-|$)} $value]} {
    return en
  }
  return ""
}

proc ::fossilhub::i18n::cookieValue {raw name} {
  foreach item [split $raw {;}] {
    set item [string trim $item]
    set separator [string first = $item]
    if {$separator < 1} {
      continue
    }
    if {[string range $item 0 [expr {$separator - 1}]] eq $name} {
      return [string range $item [expr {$separator + 1}] end]
    }
  }
  return ""
}

proc ::fossilhub::i18n::fromSources {cookieHeader acceptLanguage} {
  set locale [::fossilhub::i18n::normalize \
    [::fossilhub::i18n::cookieValue $cookieHeader fh_locale]]
  if {$locale ne ""} {
    return $locale
  }
  foreach range [split $acceptLanguage ,] {
    set language [lindex [split [string trim $range] {;}] 0]
    set locale [::fossilhub::i18n::normalize $language]
    if {$locale ne ""} {
      return $locale
    }
  }
  return en
}

proc ::fossilhub::i18n::use {locale} {
  variable activeLocale
  set locale [::fossilhub::i18n::normalize $locale]
  if {$locale eq ""} {
    set locale en
  }
  set activeLocale $locale
  return $activeLocale
}

proc ::fossilhub::i18n::useRequest {} {
  set cookies [wapp-param HTTP_COOKIE ""]
  set languages [wapp-param HTTP_ACCEPT_LANGUAGE ""]
  return [::fossilhub::i18n::use \
    [::fossilhub::i18n::fromSources $cookies $languages]]
}

proc ::fossilhub::i18n::locale {} {
  variable activeLocale
  return $activeLocale
}

proc ::fossilhub::i18n::t {key} {
  variable activeLocale
  variable messages
  if {[dict exists $messages $activeLocale $key]} {
    return [dict get $messages $activeLocale $key]
  }
  if {[dict exists $messages en $key]} {
    return [dict get $messages en $key]
  }
  return $key
}

proc ::fossilhub::i18n::phrase {value} {
  variable activeLocale
  variable phrases
  if {[dict exists $phrases $activeLocale $value]} {
    return [dict get $phrases $activeLocale $value]
  }
  return $value
}

proc ::fossilhub::i18n::validReturnTo {value} {
  expr {
    [string length $value] <= 2048 &&
    [regexp {^/[A-Za-z0-9._~!$&'()*+,;=:@%/?#-]*$} $value] &&
    ![string match {//*} $value] &&
    [string first {\\} $value] < 0
  }
}

proc ::fossilhub::i18n::returnTo {value} {
  if {[::fossilhub::i18n::validReturnTo $value]} {
    return $value
  }
  return /
}
