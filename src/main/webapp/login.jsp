<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.BookingDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="com.woxsen.greenmobility.util.CookieUtil" %>
<%@ page import="java.math.BigDecimal" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    String pageTitle = "Login";
    String loginError = null;

    // COOKIE: a previously remembered email pre-fills the form. This survives
    // logout and browser restarts, which the HttpSession deliberately does not.
    String rememberedEmail = CookieUtil.read(request, CookieUtil.REMEMBERED_EMAIL);

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        boolean rememberMe = request.getParameter("rememberMe") != null;
        try {
            Student student = new StudentDAO().authenticate(email, password);
            if (student != null) {
                // SESSION: identity for this browsing session only.
                session.setAttribute("student", student);

                // COOKIE: only the email, never the password, and only on request.
                if (rememberMe) {
                    CookieUtil.write(request, response,
                            CookieUtil.REMEMBERED_EMAIL, email, CookieUtil.ONE_MONTH);
                } else {
                    CookieUtil.delete(request, response, CookieUtil.REMEMBERED_EMAIL);
                }

                response.sendRedirect(request.getContextPath() +
                        (student.isAdmin() ? "/adminDashboard.jsp" : "/availability.jsp"));
                return;
            } else {
                loginError = "Incorrect email or password.";
            }
        } catch (Exception e) {
            loginError = "Could not reach the database: " + e.getMessage();
        }
    }

    // Keep whatever the student just typed on a failed attempt, else the cookie.
    String emailValue = request.getParameter("email") != null
            ? request.getParameter("email")
            : (rememberedEmail != null ? rememberedEmail : "");

    // Live campus figures for the hero panel. Deliberately non-fatal: if the DB is
    // unreachable the login form must still render so the error above can be shown.
    BigDecimal campusCo2 = null;
    int campusTrips = 0;
    try {
        campusCo2 = new StudentDAO().getCampusTotalCo2Saved();
        campusTrips = new BookingDAO().getCampusTotalTrips();
    } catch (Exception ignored) {
    }

    request.setAttribute("mainClass", "");
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="row g-0 min-vh-100">

    <!-- Brand / value-proposition panel -->
    <div class="col-lg-6 hero-panel d-flex align-items-center">
        <span class="hero-orb o1"></span>
        <span class="hero-orb o2"></span>

        <div class="hero-inner p-4 p-lg-5 w-100" style="max-width: 560px; margin-left: auto;">
            <div class="d-flex align-items-center gap-2 mb-4" data-anim="hero">
                <span class="brand-mark"><i class="bi bi-ev-front-fill"></i></span>
                <span class="fs-6 fw-bold">Campus Green Mobility</span>
            </div>

            <%-- Animated as one block on purpose: the second line's gradient is painted
                 with background-clip:text, which only survives while the <h1> stays a
                 single unbroken text box. Splitting it into per-word or per-character
                 spans would give each fragment its own gradient and wreck the effect. --%>
            <h1 class="hero-title mb-3" data-anim="hero">
                Ride green.<br><span class="accent">Track your impact.</span>
            </h1>
            <p class="hero-lead mb-4" data-anim="hero">
                Book EV shuttle and shared-bike slots across campus, and see exactly
                how much CO<sub>2</sub> you save versus taking a private vehicle.
            </p>

            <ul class="list-unstyled hero-features mb-4">
                <li data-anim="hero"><i class="bi bi-broadcast"></i> Live seat availability, updated as students book</li>
                <li data-anim="hero"><i class="bi bi-shield-check"></i> Guaranteed seats &mdash; no overbooking, ever</li>
                <li data-anim="hero"><i class="bi bi-graph-up-arrow"></i> Personal carbon savings tracked per trip</li>
            </ul>

            <% if (campusCo2 != null) { %>
            <div class="d-flex gap-4 hero-stats pt-3" data-anim="hero">
                <div>
                    <div class="hero-stat-value"
                         data-count="<%= campusCo2 %>" data-decimals="2" data-suffix=" kg">0</div>
                    <div class="hero-stat-label">CO<sub>2</sub> saved campus-wide</div>
                </div>
                <div class="hero-stat-divider"></div>
                <div>
                    <div class="hero-stat-value" data-count="<%= campusTrips %>">0</div>
                    <div class="hero-stat-label">green trips booked</div>
                </div>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Login panel -->
    <div class="col-lg-6 d-flex align-items-center justify-content-center bg-body-tertiary">
        <div class="p-4 w-100" style="max-width: 420px;">
            <h2 class="h3 text-forest mb-1" data-anim="card">Welcome back</h2>
            <p class="text-muted mb-4" data-anim="card">Sign in to book a shuttle or bike slot.</p>

            <c:if test="<%= loginError != null %>">
                <div class="alert alert-danger d-flex align-items-center gap-2" role="alert" data-anim="card">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div><%= loginError %></div>
                </div>
            </c:if>

            <%-- Only the field WRAPPERS carry data-anim, never the <input>s themselves:
                 the email field is autofocus'd, and animating a focused input (or one a
                 password manager is trying to attach its overlay to) is a good way to
                 fight the browser. Moving the wrapper gets the same visual result. --%>
            <form method="post" action="login.jsp" novalidate data-busy>
                <div class="mb-3" data-anim="card">
                    <label for="email" class="form-label">College email</label>
                    <div class="input-group">
                        <span class="input-group-text bg-white text-muted"><i class="bi bi-envelope"></i></span>
                        <input type="email" class="form-control border-start-0 ps-0" id="email" name="email"
                               placeholder="you@woxsen.edu.in" required autofocus
                               value="<%= emailValue %>">
                    </div>
                    <% if (rememberedEmail != null && request.getParameter("email") == null) { %>
                        <div class="form-text text-success">
                            <i class="bi bi-check-circle me-1"></i>Filled in from your last visit
                        </div>
                    <% } %>
                </div>

                <div class="mb-4" data-anim="card">
                    <label for="password" class="form-label">Password</label>
                    <div class="input-group">
                        <span class="input-group-text bg-white text-muted"><i class="bi bi-lock"></i></span>
                        <input type="password" class="form-control border-start-0 ps-0" id="password" name="password"
                               placeholder="Enter your password" required>
                        <button class="btn btn-outline-secondary" type="button" id="togglePw"
                                aria-label="Show password">
                            <i class="bi bi-eye" id="togglePwIcon"></i>
                        </button>
                    </div>
                </div>

                <div class="form-check mb-4" data-anim="card">
                    <input class="form-check-input" type="checkbox" id="rememberMe" name="rememberMe"
                           <%= rememberedEmail != null ? "checked" : "" %>>
                    <label class="form-check-label small" for="rememberMe">
                        Remember my email on this device
                    </label>
                </div>

                <button type="submit" class="btn btn-primary btn-lg w-100" data-anim="card" data-ripple>
                    <i class="bi bi-box-arrow-in-right me-1"></i> Log In
                </button>
            </form>

            <div class="demo-hint mt-4 p-3" data-anim="card">
                <div class="d-flex justify-content-between align-items-center gap-2">
                    <div class="small text-muted">
                        <i class="bi bi-info-circle me-1"></i>
                        Demo account &mdash; <code>sid@woxsen.edu.in</code>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-success flex-shrink-0" id="fillDemo"
                            data-ripple>
                        Use demo
                    </button>
                </div>
            </div>

            <p class="text-center small text-muted mt-4 mb-0" data-anim="card">
                New here? <a href="signup.jsp" class="fw-semibold">Create an account</a>
            </p>
        </div>
    </div>
</div>

<script>
    document.getElementById('fillDemo').addEventListener('click', function () {
        document.getElementById('email').value = 'sid@woxsen.edu.in';
        document.getElementById('password').value = 'password123';
        document.getElementById('password').focus();
    });

    document.getElementById('togglePw').addEventListener('click', function () {
        var pw = document.getElementById('password');
        var icon = document.getElementById('togglePwIcon');
        var showing = pw.type === 'text';
        pw.type = showing ? 'password' : 'text';
        icon.className = showing ? 'bi bi-eye' : 'bi bi-eye-slash';
        this.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
    });
</script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
