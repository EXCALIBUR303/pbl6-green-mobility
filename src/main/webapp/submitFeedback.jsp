<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.FeedbackDAO" %>
<%@ page import="com.woxsen.greenmobility.model.RideFeedback" %>
<%
    int bookingId = Integer.parseInt(request.getParameter("bookingId"));
    String category = request.getParameter("category");
    String comment = request.getParameter("comment");

    Integer rating = null;
    try {
        rating = Integer.parseInt(request.getParameter("rating"));
    } catch (Exception ignored) {
    }

    try {
        new FeedbackDAO().submitFeedback(bookingId, loggedInStudent.getStudentId(),
                RideFeedback.KIND_POST_RIDE, rating, category, comment);
        response.sendRedirect(request.getContextPath() +
                "/history.jsp?status=success&msg=Thanks for the feedback!");
    } catch (IllegalArgumentException e) {
        response.sendRedirect(request.getContextPath() +
                "/history.jsp?status=error&msg=Could not submit feedback: " + e.getMessage());
    }
%>
