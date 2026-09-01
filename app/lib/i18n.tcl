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
  variable templateTranslations [list \
    {Owned strata and repositories where you collaborate.} {你拥有的地层，以及你参与协作的仓库。} \
    {Owned strata and collaborations in one field ledger.} {在同一份现场账册中查看自有仓库与协作仓库。} \
    {Open work across repositories you can access. FossilHub does not invent assignment fields that are absent from the repository.} {汇总你可访问仓库中的待办工作。FossilHub 不会凭空添加仓库中不存在的指派字段。} \
    {Create a repository or ask an owner to add you as a collaborator.} {创建一个仓库，或请所有者将你添加为协作者。} \
    {Lowercase letters, numbers, and single hyphens. The URL cannot be renamed in this milestone.} {仅使用小写字母、数字和单个连字符；当前阶段不支持修改 URL。} \
    {Public — visible and cloneable by everyone} {公开 — 所有人均可查看和克隆} \
    {Private — members only} {私有 — 仅成员可访问} \
    {These operations require a recently authenticated session and the exact repository name.} {这些操作需要近期完成身份验证，并输入准确的仓库名称。} \
    {The repository file is in quarantine and is not readable or cloneable.} {仓库文件已被隔离，当前不可读取或克隆。} \
    {Theme is stored only in this browser. System mode follows your device preference.} {主题只保存在当前浏览器中；系统模式跟随设备偏好。} \
    {Signing in will be blocked and every active session will close. Repository custody remains intact for administrator review.} {账户将无法登录，所有活动会话都会关闭；仓库保管关系仍会保留，供管理员检查。} \
    {Email is private and is never shown on your public profile.} {邮箱属于私密信息，不会显示在公开主页中。} \
    {High-risk administrator actions require a fresh identity check.} {高风险管理员操作需要重新验证身份。} \
    {These actions require a password check from the last ten minutes and produce an audit event.} {这些操作要求最近十分钟内完成密码验证，并会生成审计事件。} \
    {Safe checks only; paths, private names, logs, and credentials are omitted.} {仅显示安全检查结果；路径、私有名称、日志和凭据均会省略。} \
    {Safe platform totals without credentials, paths, or private content.} {仅显示不含凭据、路径或私有内容的平台汇总。} \
    {Submitted content, session material, request identifiers, and internal detail are excluded.} {已排除提交内容、会话材料、请求标识和内部细节。} \
    {Public text only. Never enter credentials or operational logs.} {只能填写公开文本，切勿输入凭据或运维日志。} \
    {Only non-secret application policy is editable here.} {这里只允许编辑不含秘密的应用策略。} \
    {Integrity failure moves the file out of publication and marks the registry record quarantined.} {完整性检查失败会将文件移出发布范围，并把注册记录标记为隔离。} \
    {This repository is quarantined. Browser restore is deliberately blocked pending trusted recovery.} {此仓库已隔离；在可信恢复完成前，浏览器恢复操作会被主动阻止。} \
    {Repositories per user} {每位用户的仓库数} \
    {Default repository visibility} {默认仓库可见性} \
    {Repository quota · MiB} {仓库配额 · MiB} \
    {Password &amp; sessions} {密码与会话} \
    {Account navigation} {账户导航} \
    {Settings sections} {设置分区} \
    {Toggle color theme} {切换配色主题} \
    {Color theme} {配色主题} \
    {Repository permission layers} {仓库权限层级} \
    {Confirm new password} {确认新密码} \
    {Current password} {当前密码} \
    {New password} {新密码} \
    {Change password} {修改密码} \
    {Active sessions} {活动会话} \
    {Signed in as} {当前登录身份} \
    {Last seen %s · expires %s · mark %s} {最后活动 %s · 到期 %s · 标记 %s} \
    {Public repositories} {公开仓库} \
    {Public activity} {公开活动} \
    {Public profile} {公开主页} \
    {No open Tickets in your repositories.} {你的仓库中没有未关闭的 Ticket。} \
    {No repositories yet} {尚无仓库} \
    {No repositories match these filters.} {没有仓库符合这些筛选条件。} \
    {No users match these filters.} {没有用户符合这些筛选条件。} \
    {No audit events match.} {没有符合条件的审计事件。} \
    {No repository relationships.} {没有仓库关联关系。} \
    {Your repositories} {你的仓库} \
    {New repository} {新建仓库} \
    {Create repository} {创建仓库} \
    {Repository name} {仓库名称} \
    {Display title} {显示标题} \
    {Default branch} {默认分支} \
    {Repository record} {仓库记录} \
    {Save repository} {保存仓库} \
    {Collaborators} {协作者} \
    {Add or update} {添加或更新} \
    {Owner controls} {所有者控制} \
    {Transfer to username} {转移给用户名} \
    {Transfer ownership} {转移所有权} \
    {Archive repository} {归档仓库} \
    {Archived repository} {已归档仓库} \
    {Restore repository} {恢复仓库} \
    {Type <code>%s</code> to confirm} {输入 <code>%s</code> 以确认} \
    {Type <code>%s</code> to archive} {输入 <code>%s</code> 以归档} \
    {Type <code>%s</code> to restore} {输入 <code>%s</code> 以恢复} \
    {Save profile} {保存资料} \
    {Deactivate account} {停用账户} \
    {Appearance} {外观} \
    {Biography} {个人简介} \
    {Website} {网站} \
    {Location} {所在地} \
    {Light} {浅色} \
    {Dark} {深色} \
    {System} {跟随系统} \
    {Open Tickets} {未关闭的 Ticket} \
    {Recent activity} {最近活动} \
    {Collaborations} {协作仓库} \
    {Owned} {自有仓库} \
    {Application health} {应用健康状态} \
    {Application revision} {应用修订} \
    {Catalogue database} {目录数据库} \
    {Catalogue indexed} {目录索引状态} \
    {Platform database} {平台数据库} \
    {Protected file modes} {受保护文件权限} \
    {Repository readability} {仓库可读性} \
    {Runtime ownership} {运行时所有权} \
    {Operational overview} {运行概览} \
    {Recent audit activity} {近期审计活动} \
    {Search identities, review status, and open a controlled record.} {搜索身份、检查状态并打开受控记录。} \
    {Repository relationships} {仓库关联关系} \
    {Platform policy} {平台策略} \
    {Maintenance banner} {维护横幅} \
    {Storage budget} {存储预算} \
    {Controlled actions} {受控操作} \
    {Rebuild catalogue} {重建目录} \
    {Run integrity check} {运行完整性检查} \
    {Inspect health} {检查健康状态} \
    {Confirm your password} {确认你的密码} \
    {Confirm identity} {确认身份} \
    {Exact action} {准确操作} \
    {Export CSV} {导出 CSV} \
    {Action / mark} {操作 / 标记} \
    {Last sign-in} {最近登录} \
    {Platform role} {平台角色} \
    {Change role} {修改角色} \
    {Revoke all sessions} {撤销全部会话} \
    {Registration} {注册} \
    {Save platform policy} {保存平台策略} \
    {SORT BY} {排序} \
    {Surface · recent} {地表 · 最近活动} \
    {Deep time · oldest} {深层 · 最早优先} \
    {Specimen · name} {标本 · 名称} \
    {Mass · largest} {体量 · 最大优先} \
    {One thread for everything that happened.} {所有变化，汇成一条时间线。} \
    {Check-ins, ticket changes, wiki edits, and forum posts land on a single chronological timeline — with forks and merges drawn as they happen.} {check-in、Ticket 变更、Wiki 编辑和论坛发言按时间汇入同一条记录，分叉与合并也会随事件呈现。} \
    {No tab-switching between tools. The timeline is the project's complete field journal: who changed what, when a bug was closed, which page was rewritten — all in one scroll, all searchable from one box.} {不必在多个工具之间来回切换。时间线就是项目完整的现场日志：谁改了什么、问题何时关闭、哪个页面被重写，都能在同一处滚动查看和搜索。} \
    {Documentation that checks out with the code.} {与代码一同检出的文档。} \
    {The wiki and the docs tree version alongside source. Check out any commit and the manuals match it exactly — no drift between release notes and reality.} {Wiki 与文档树和源码一起版本化。检出任意提交，手册都会与当时的代码准确对应，不会让发布说明偏离现实。} \
    {Edit pages from the browser or from your checkout — either path saves a real commit with a real hash. A wiki page is never “just content”: it is an artifact in the repository like everything else.} {无论在浏览器还是本地检出中编辑页面，都会保存为带真实哈希的提交。Wiki 页面不是孤立内容，而是和其他资料一样属于仓库 artifact。} \
    {The bug tracker never leaves the repository.} {问题跟踪始终留在仓库中。} \
    {Tickets and forum threads travel inside the same artifact as the code. Clone the repo, get its whole history of arguments.} {Ticket 与论坛讨论和代码保存在同一个 artifact 中；克隆仓库，也会取得完整的讨论历史。} \
    {Every ticket change and every forum reply becomes part of the timeline you already read. Mirror a project to a laptop before a flight and its open questions fly with you.} {每次 Ticket 变更和论坛回复都会进入同一条时间线。出发前把项目镜像到电脑，尚未解决的问题也会随你离线同行。} \
    {One binary does the work of a rack.} {一个二进制，完成整套服务。} \
    {A single static executable initializes, serves, syncs, and renders. Point it at a file and it becomes the forge.} {一个静态可执行文件即可初始化、服务、同步与渲染；将它指向仓库文件，就得到完整的协作站点。} \
    {No daemons, no config files, no database server. The web UI ships inside the same binary that stores the data.} {无需额外守护进程、配置文件或数据库服务器；Web 界面与数据能力封装在同一个二进制中。} \
    {Distributed when you want it, centralized when you need it: peers sync directly over HTTP(S) in autosync mode, while a single server can host hundreds of projects. Backup is one file copy.} {需要时分布式，需要时集中式：节点可通过 HTTP(S) 自动同步，一台服务器也能托管大量项目；备份只需复制一个文件。} \
    {Stratum 01 · Timeline} {地层 01 · 时间线} \
    {Stratum 02 · Wiki + embedded docs} {地层 02 · Wiki 与内嵌文档} \
    {Stratum 03 · Tickets + forum} {地层 03 · Tickets 与论坛} \
    {Stratum 04 · The engine} {地层 04 · 引擎} \
    {self-contained executable} {自包含可执行文件} \
    {external dependencies} {外部依赖} \
    {first check-in by D.&nbsp;R.&nbsp;Hipp} {D.&nbsp;R.&nbsp;Hipp 的首次 check-in} \
    {of history in every clone} {历史包含在每次克隆中} \
    {Start a dig} {开始勘探} \
    {Browse repositories} {浏览仓库} \
    {Field manual} {现场手册} \
    {Release history} {发布历史} \
    {SQLite, the sibling project} {SQLite，姊妹项目} \
    {Site rules} {站点规则} \
    {Status board} {状态面板} \
    {Contact the wardens} {联系管理员} \
    {The hub} {本站} \
    {Bedrock · Nothing below this line} {基岩 · 此线以下再无地层} \
    {Upstream} {上游项目} \
    {Privacy} {隐私} \
    {Security} {安全} \
    {SPECIMEN LABEL} {标本标签} \
    {FOSSILHUB ▸ DIGS ▸ } {FOSSILHUB ▸ 仓库 ▸ } \
    {Private repository · browser members only} {私有仓库 · 仅成员可在浏览器访问} \
    {Survey trunk files} {勘测 trunk 文件} \
    {live Fossil artifact} {实时 Fossil artifact} \
    {Tcl server-rendered} {Tcl 服务端渲染} \
    {updated @@RELATIVE_TIME@@} {更新于 @@RELATIVE_TIME@@} \
    {artifacts in one file} {个 artifact 收纳在单文件中} \
    {wiki versions} {个 Wiki 版本} \
    {open tickets} {个未关闭 Ticket} \
    {contributors} {位贡献者} \
    {Repository facts} {仓库事实} \
    {FossilHub surfaces} {FossilHub 界面} \
    {Composition} {构成} \
    {SITE ID} {站点 ID} \
    {PROJECT} {项目} \
    {OPENED} {创建时间} \
    {LAST FIND} {最近发现} \
    {ARTIFACTS} {ARTIFACT 数} \
    {DEPTH} {深度} \
    {SOURCE} {数据源} \
    {RENDERER} {渲染器} \
    {Files} {文件} \
    {Docs} {文档} \
    {Timeline} {时间线} \
    {Forum } {论坛 } \
    {Tickets } {Tickets } \
    {Wiki } {Wiki } \
    {Repository custody} {仓库保管} \
    {User custody} {用户保管} \
    {Audit ledger} {审计账本} \
    {Display name} {显示名称} \
    {Description} {描述} \
    {Visibility} {可见性} \
    {Username} {用户名} \
    {Repositories} {仓库} \
    {Repository} {仓库} \
    {Created} {创建时间} \
    {Updated} {更新时间} \
    {Status} {状态} \
    {State} {状态} \
    {Outcome} {结果} \
    {Actor} {操作者} \
    {Date} {日期} \
    {Sessions} {会话} \
    {Search} {搜索} \
    {Filter} {筛选} \
    {Remove} {移除} \
    {Manage} {管理} \
    {Open} {打开} \
    {Profile} {资料} \
    {Public} {公开} \
    {Private} {私有} \
    {Owner} {所有者} \
    {Maintainer} {维护者} \
    {Writer} {写入者} \
    {Triage} {分诊者} \
    {Reader} {只读者} \
    {Role} {角色}]
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
      {密码只在本地验证，绝不会保留在审计账本中。} \
    owner 所有者 \
    maintainer 维护者 \
    writer 写入者 \
    triage 分诊者 \
    reader 只读者 \
    public 公开 \
    private 私有 \
    active 活跃 \
    archived 已归档 \
    quarantined 已隔离 \
    success 成功 \
    failure 失败 \
    administrator 管理员 \
    user 用户 \
    disabled 已禁用 \
    deactivated 已停用 \
    open 开放 \
    closed 关闭 \
    ok 正常 \
    missing 缺失 \
    {Current session} {当前会话} \
    {Signed-in session} {已登录会话} \
    Revoke 撤销 \
    {created an account} {创建了账户} \
    {updated their profile} {更新了个人资料} \
    {created a repository} {创建了仓库} \
    {updated repository settings} {更新了仓库设置} \
    {added a collaborator} {添加了协作者} \
    {removed a collaborator} {移除了协作者} \
    {transferred a repository} {转移了仓库} \
    {archived a repository} {归档了仓库} \
    {restored a repository} {恢复了仓库} \
    {created a file} {创建了文件} \
    {updated a file} {更新了文件} \
    {deleted a file} {删除了文件} \
    {created a Wiki page} {创建了 Wiki 页面} \
    {updated a Wiki page} {更新了 Wiki 页面} \
    {opened a Ticket} {创建了 Ticket} \
    {updated a Ticket} {更新了 Ticket} \
    {opened a discussion} {发起了讨论} \
    {replied to a discussion} {回复了讨论} \
    {You do not own a repository yet.} {你还没有自己的仓库。} \
    {No collaboration invitations yet.} {暂无协作邀请。} \
    {Your activity ledger is empty.} {你的活动账本还是空的。} \
    {No public repositories yet.} {暂无公开仓库。} \
    {No public repository activity yet.} {暂无公开仓库活动。} \
    {No biography recorded.} {尚未填写个人简介。} \
    Users 用户 \
    Active 活跃 \
    {Active repositories} {活跃仓库} \
    {Activity · 24h} {24 小时活动} \
    {Failures · 24h} {24 小时失败} \
    {registered identities} {已注册身份} \
    {able to sign in} {可正常登录} \
    {registry records} {注册记录} \
    {published strata} {已发布地层} \
    {audited events} {审计事件} \
    {review required} {需要检查} \
    All 全部 \
    User 用户 \
    Administrator 管理员 \
    Disabled 已禁用 \
    Deactivated 已停用 \
    Archived 已归档 \
    Quarantined 已隔离 \
    {Restore access} {恢复访问} \
    {Disable access} {禁用访问} \
    Unassigned 未分配 \
    {No recorded activity.} {暂无活动记录。}]]
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
  if {$cookies eq ""} {
    set cookies [wapp-param {.hdr:Cookie} ""]
  }
  set languages [wapp-param HTTP_ACCEPT_LANGUAGE ""]
  if {$languages eq ""} {
    set languages [wapp-param {.hdr:Accept-Language} ""]
  }
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

proc ::fossilhub::i18n::template {value} {
  variable activeLocale
  variable templateTranslations
  if {$activeLocale ne "zh-CN"} {
    return $value
  }
  return [string map $templateTranslations $value]
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
