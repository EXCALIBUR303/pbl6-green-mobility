<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.PointsDAO" %>
<%@ page import="com.woxsen.greenmobility.model.PointEvent" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="com.woxsen.greenmobility.service.PointsService" %>
<%
    int REDEMPTION_COST = PointsService.REDEMPTION_COST;

    StudentDAO studentDAO = new StudentDAO();
    boolean redeemed = studentDAO.redeemFreeRide(loggedInStudent.getStudentId(), REDEMPTION_COST);

    if (redeemed) {
        new PointsDAO().logEvent(loggedInStudent.getStudentId(), PointEvent.TYPE_REDEMPTION,
                -REDEMPTION_COST, "Redeemed for a free ride voucher");

        Student refreshed = studentDAO.findById(loggedInStudent.getStudentId());
        session.setAttribute("student", refreshed);

        response.sendRedirect(request.getContextPath() +
                "/rewards.jsp?status=success&msg=Voucher redeemed! It'll be applied to your next booking automatically.");
    } else {
        response.sendRedirect(request.getContextPath() +
                "/rewards.jsp?status=error&msg=Not enough points for a voucher yet.");
    }
%>
