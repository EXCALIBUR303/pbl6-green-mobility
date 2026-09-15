<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.BookingDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.FeedbackDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.PointsDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Booking" %>
<%@ page import="com.woxsen.greenmobility.model.PointEvent" %>
<%@ page import="com.woxsen.greenmobility.model.RideFeedback" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="com.woxsen.greenmobility.service.PointsService" %>
<%
    int bookingId = Integer.parseInt(request.getParameter("bookingId"));
    String category = request.getParameter("category");
    String comment = request.getParameter("comment");

    BookingDAO bookingDAO = new BookingDAO();
    boolean cancelled = bookingDAO.cancelBooking(bookingId, loggedInStudent.getStudentId());

    if (cancelled) {
        StudentDAO studentDAO = new StudentDAO();
        String successMsg = "Booking cancelled. Your seat has been released.";

        // A cancelled ride that had spent a rewards voucher gets that spend
        // refunded -- the "free ride" never actually happened, so the points
        // shouldn't stay spent. reward_redeemed never changes once a booking
        // is created, so reading it via a fresh lookup right after the
        // ownership+status-checked cancel above is safe.
        Booking cancelledBooking = bookingDAO.findById(bookingId);
        if (cancelledBooking != null && cancelledBooking.isRewardRedeemed()) {
            studentDAO.addPoints(loggedInStudent.getStudentId(), PointsService.REDEMPTION_COST);
            new PointsDAO().logEvent(loggedInStudent.getStudentId(), PointEvent.TYPE_REVOCATION,
                    PointsService.REDEMPTION_COST, "Refund: cancelled a free-ride voucher booking");
            successMsg += " Your " + PointsService.REDEMPTION_COST + " redeemed points were refunded.";
        }

        // Lightweight and optional by design -- a student who just wants out
        // shouldn't be blocked by a form, so this never affects the redirect
        // below even if it fails or was left blank.
        if (category != null && !category.isBlank()) {
            try {
                new FeedbackDAO().submitFeedback(bookingId, loggedInStudent.getStudentId(),
                        RideFeedback.KIND_CANCELLATION, null, category, comment);
            } catch (Exception ignored) {
            }
        }

        // Refresh the session copy: the CO2 reversal, and possibly the points
        // refund above, both need to show up in the nav/impact figures without
        // a re-login, same pattern as processBooking.jsp.
        Student refreshed = studentDAO.findById(loggedInStudent.getStudentId());
        session.setAttribute("student", refreshed);

        response.sendRedirect(request.getContextPath() +
                "/history.jsp?status=success&msg=" + successMsg);
    } else {
        response.sendRedirect(request.getContextPath() +
                "/history.jsp?status=error&msg=Could not cancel that booking. It may already be underway or gone.");
    }
%>
