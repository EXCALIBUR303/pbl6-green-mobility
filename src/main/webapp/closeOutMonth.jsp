<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.ArchiveDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.time.LocalDate" %>
<%
    // POST-only: closing out a month changes stored state, so it must not be
    // reachable by a plain link or a refresh of a GET.
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(request.getContextPath() + "/history.jsp");
        return;
    }

    int year = Integer.parseInt(request.getParameter("year"));
    int month = Integer.parseInt(request.getParameter("month"));

    ArchiveDAO archiveDAO = new ArchiveDAO();
    BigDecimal archived = archiveDAO.closeOutMonth(loggedInStudent.getStudentId(), year, month);

    String redirect;
    if (archived == null) {
        redirect = "/history.jsp?status=error&msg=Nothing to close out for that month.";
    } else {
        // Refresh the session copy so the navbar and stat cards show the reset total.
        Student refreshed = new StudentDAO().findById(loggedInStudent.getStudentId());
        session.setAttribute("student", refreshed);

        redirect = "/history.jsp?status=success&msg=Month closed out. "
                + archived + " kg archived and your running total is reset to 0.";
    }

    response.sendRedirect(request.getContextPath() + redirect);
%>
