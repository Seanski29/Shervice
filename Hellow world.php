<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Simple sidebar · logo · quick actions</title>
  <link rel="stylesheet" href="styles.css">
  <!-- Font Awesome 6 (free) for simple icons, optional but nice -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">

</head>
<body>
  <!-- SIDEBAR (left) with 5 options -->
  <aside class="sidebar">
    <div class="sidebar-header">
      ☰ Menu<span>v2</span>
    </div>
    <ul class="nav">
      <!-- five options, first active for nicer look -->
      <li class="nav-item active">
        <i class="fas fa-chart-pie"></i>
        <span>Dashboard</span>
      </li>
      <li class="nav-item">
        <i class="fas fa-file-alt"></i>
        <span>Documents</span>
      </li>
      <li class="nav-item">
        <i class="fas fa-users"></i>
        <span>Team</span>
      </li>
      <li class="nav-item">
        <i class="fas fa-calendar-alt"></i>
        <span>Calendar</span>
      </li>
      <li class="nav-item">
        <i class="fas fa-cog"></i>
        <span>Settings</span>
      </li>
    </ul>
    <div class="sidebar-footer">
      ⚡ 5 options • simple layout
    </div>
  </aside>

  <!-- MAIN page area -->
  <main class="main">
    <div class="main-top-bar">
      <i class="fas fa-bell" style="opacity:0.5; margin-right: 20px;"></i>
      <span>example@simple.page</span>
    </div>

    <!-- card that contains logo placeholder, title and quick action buttons -->
    <div class="content-card">
      
      <!-- LOGO placeholder (left side inside main) -->
      <div class="logo-placeholder">
        <div class="logo-box">
          <i class="fas fa-cube"></i>
        </div>
        <span>
          Logo placeholder <strong>● svg</strong>
        </span>
      </div>

      <!-- TITLE block -->
      <div class="page-title">
        <h1>Simple page<br>with intent</h1>
        <div class="sub">
          <i class="fas fa-arrow-right"></i>
          <span>Main area — logo, title and quick actions below</span>
        </div>
      </div>

      <!-- QUICK ACTION BUTTONS (three) -->
      <div class="quick-actions">
        <div class="action-btn">
          <i class="fas fa-download"></i> Import
        </div>
        <div class="action-btn">
          <i class="fas fa-share-alt"></i> Share
        </div>
        <div class="action-btn">
          <i class="fas fa-plus-circle"></i> Create
        </div>
      </div>

      <!-- tiny footnote (just to show the three buttons) -->
      <div class="meta-note">
        <i class="fas fa-bolt" style="color:#3b7aee;"></i>
        <span>3 quick action buttons · static demo</span>
        <hr>
      </div>
    </div>

    <!-- extra subtle padding (main flex can grow) -->
    <div style="flex:1; min-height: 40px;"></div>
  </main>
</body>
</html>
