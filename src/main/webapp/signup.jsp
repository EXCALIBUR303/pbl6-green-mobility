<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    String pageTitle = "Create Account";
    String signupError = null;
    String nameValue = "";
    String emailValue = "";

    // Restricted to the campus domain -- this is a campus mobility system, not
    // an open public signup, matching the seeded demo accounts' convention.
    String REQUIRED_DOMAIN = "@woxsen.edu.in";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        nameValue = request.getParameter("name");
        emailValue = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        if (nameValue == null || nameValue.isBlank()) {
            signupError = "Please enter your name.";
        } else if (emailValue == null || !emailValue.toLowerCase().endsWith(REQUIRED_DOMAIN)) {
            signupError = "Please use your " + REQUIRED_DOMAIN + " email.";
        } else if (password == null || password.length() < 6) {
            signupError = "Password must be at least 6 characters.";
        } else if (!password.equals(confirmPassword)) {
            signupError = "Passwords don't match.";
        } else {
            try {
                Student created = new StudentDAO().createStudent(nameValue.trim(), emailValue.trim().toLowerCase(), password);
                if (created == null) {
                    signupError = "That email is already registered. Try logging in instead.";
                } else {
                    session.setAttribute("student", created);
                    response.sendRedirect(request.getContextPath() + "/availability.jsp");
                    return;
                }
            } catch (Exception e) {
                signupError = "Could not create your account: " + e.getMessage();
            }
        }
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<div class="d-flex justify-content-center py-5">
    <div class="card p-4 p-lg-5 w-100" style="max-width: 460px;">
        <h2 class="h3 text-forest mb-1">Create your account</h2>
        <p class="text-muted mb-4">Join Campus Green Mobility to book shuttles and bikes.</p>

        <c:if test="<%= signupError != null %>">
            <div class="alert alert-danger d-flex align-items-center gap-2" role="alert">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <div><%= signupError %></div>
            </div>
        </c:if>

        <form method="post" action="signup.jsp" novalidate data-busy>
            <div class="mb-3">
                <label for="name" class="form-label">Full name</label>
                <input type="text" class="form-control" id="name" name="name" required autofocus
                       value="<%= nameValue %>">
            </div>
            <div class="mb-3">
                <label for="email" class="form-label">College email</label>
                <div class="input-group">
                    <span class="input-group-text bg-white text-muted"><i class="bi bi-envelope"></i></span>
                    <input type="email" class="form-control border-start-0 ps-0" id="email" name="email"
                           placeholder="you@woxsen.edu.in" required value="<%= emailValue %>">
                </div>
            </div>
            <div class="mb-3">
                <label for="password" class="form-label">Password</label>
                <input type="password" class="form-control" id="password" name="password" required minlength="6">
            </div>
            <div class="mb-4">
                <label for="confirmPassword" class="form-label">Confirm password</label>
                <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" required minlength="6">
            </div>
            <button type="submit" class="btn btn-primary btn-lg w-100" data-ripple>
                <i class="bi bi-person-plus me-1"></i>Create account
            </button>
        </form>

        <p class="text-center small text-muted mt-4 mb-0">
            Already have an account? <a href="login.jsp" class="fw-semibold">Log in</a>
        </p>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
