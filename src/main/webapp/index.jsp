<%
    // Simple entry point: send logged-in students to the availability board,
    // everyone else to the login page.
    if (session.getAttribute("student") != null) {
        response.sendRedirect(request.getContextPath() + "/availability.jsp");
    } else {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
    }
%>
