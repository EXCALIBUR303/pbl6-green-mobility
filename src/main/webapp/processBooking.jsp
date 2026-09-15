<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.BookingDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.StudentDAO" %>
<%@ page import="com.woxsen.greenmobility.model.VehicleSlot" %>
<%@ page import="com.woxsen.greenmobility.model.Student" %>
<%@ page import="com.woxsen.greenmobility.util.CarbonCalculator" %>
<%@ page import="java.math.BigDecimal" %>
<%
    int slotId = Integer.parseInt(request.getParameter("slotId"));

    SlotDAO slotDAO = new SlotDAO();
    VehicleSlot slot = slotDAO.findById(slotId);

    if (slot == null) {
        response.sendRedirect(request.getContextPath() +
                "/availability.jsp?status=error&msg=That slot no longer exists.");
        return;
    }

    // Atomic capacity check + increment, so two students booking the last seat
    // at the same moment can't both succeed.
    boolean reserved = slotDAO.tryReserveSeat(slotId);

    if (!reserved) {
        response.sendRedirect(request.getContextPath() +
                "/availability.jsp?status=error&msg=Sorry, that slot filled up just before your booking.");
        return;
    }

    BigDecimal co2Saved = CarbonCalculator.savedKg(slot.getVehicleType(), slot.getDistanceKm());

    BookingDAO bookingDAO = new BookingDAO();
    int bookingId = bookingDAO.createBooking(loggedInStudent.getStudentId(), slotId, slot.getDistanceKm(), co2Saved);

    StudentDAO studentDAO = new StudentDAO();
    studentDAO.addCo2Saved(loggedInStudent.getStudentId(), co2Saved);

    // Spending a voucher is an explicit choice made on confirmBooking.jsp
    // (checkbox only shown when one is actually available), not a silent
    // auto-spend -- a student might want to save it for a different trip.
    // The seat itself is still claimed through the exact same capacity-checked
    // tryReserveSeat() above either way, so a voucher never bypasses
    // overbooking prevention; it just marks this booking as reward-redeemed.
    boolean wantsVoucher = "true".equals(request.getParameter("useVoucher"));
    boolean usedVoucher = wantsVoucher && studentDAO.consumeFreeRideCredit(loggedInStudent.getStudentId());
    if (usedVoucher) {
        bookingDAO.markRewardRedeemed(bookingId);
    }

    // Refresh the session copy so the nav/impact figures are correct without a re-login.
    Student refreshed = studentDAO.findById(loggedInStudent.getStudentId());
    session.setAttribute("student", refreshed);

    String successMsg = "Booked! You saved an estimated " + co2Saved + " kg of CO2.";
    if (usedVoucher) {
        successMsg += " A free ride voucher was applied.";
    }

    response.sendRedirect(request.getContextPath() +
            "/history.jsp?status=success&msg=" + successMsg);
%>
