<%@ include file="/WEB-INF/jspf/adminGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.BookingDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.FeedbackDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%
    String pageTitle = "Admin Dashboard";
    request.setAttribute("studentCount", new StudentDAO().getStudentCount());
    request.setAttribute("bookingCount", new BookingDAO().getBookingCount());
    request.setAttribute("feedbackCount", new FeedbackDAO().getFeedbackCount());
    request.setAttribute("slotCount", new SlotDAO().getUpcomingSlots().size());
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/flash.jspf" %>

<h1 class="page-title text-forest mb-1">Admin dashboard</h1>
<p class="text-secondary mb-4">Campus-wide overview &mdash; open new slots and read incoming feedback.</p>

<div class="row g-3 mb-4">
    <div class="col-sm-6 col-lg-3">
        <div class="stat-tile h-100">
            <div class="stat-value" data-count="${studentCount}">0</div>
            <div class="stat-label">Registered students</div>
            <i class="bi bi-people-fill stat-glyph"></i>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <div class="stat-tile tile-dark h-100">
            <div class="stat-value" data-count="${bookingCount}">0</div>
            <div class="stat-label">Total bookings</div>
            <i class="bi bi-calendar2-check stat-glyph"></i>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <div class="stat-tile h-100">
            <div class="stat-value" data-count="${slotCount}">0</div>
            <div class="stat-label">Slots in the system</div>
            <i class="bi bi-signpost-split stat-glyph"></i>
        </div>
    </div>
    <div class="col-sm-6 col-lg-3">
        <div class="stat-tile tile-dark h-100">
            <div class="stat-value" data-count="${feedbackCount}">0</div>
            <div class="stat-label">Feedback received</div>
            <i class="bi bi-chat-square-text stat-glyph"></i>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-md-6">
        <a href="adminSlots.jsp" class="card p-4 h-100 card-hover text-decoration-none d-block">
            <div class="d-flex align-items-center gap-3">
                <span class="vehicle-icon lg shuttle"><i class="bi bi-calendar2-plus"></i></span>
                <div>
                    <div class="fw-bold text-forest">Manage slots</div>
                    <div class="text-secondary small">Open new shuttle/bike slots for students to book.</div>
                </div>
            </div>
        </a>
    </div>
    <div class="col-md-6">
        <a href="adminFeedback.jsp" class="card p-4 h-100 card-hover text-decoration-none d-block">
            <div class="d-flex align-items-center gap-3">
                <span class="vehicle-icon lg bike"><i class="bi bi-chat-square-text"></i></span>
                <div>
                    <div class="fw-bold text-forest">Feedback inbox</div>
                    <div class="text-secondary small">Every post-ride rating and cancellation reason.</div>
                </div>
            </div>
        </a>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
