<%@ include file="/WEB-INF/jspf/adminGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="com.woxsen.greenmobility.model.VehicleSlot" %>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String pageTitle = "Manage Slots";
    List<VehicleSlot> slots = new SlotDAO().getUpcomingSlots();
    request.setAttribute("slots", slots);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/flash.jspf" %>

<h1 class="page-title text-forest mb-1">Manage slots</h1>
<p class="text-secondary mb-4">Open a new shuttle or bike slot for students to see and book.</p>

<div class="card p-4 mb-4">
    <span class="section-label d-block mb-3"><i class="bi bi-calendar2-plus me-1"></i>Open a new slot</span>
    <form method="post" action="adminCreateSlot.jsp" data-busy>
        <div class="row g-3">
            <div class="col-md-3">
                <label class="form-label small fw-semibold">Vehicle type</label>
                <select class="form-select" name="vehicleType" required>
                    <option value="EV Shuttle">EV Shuttle</option>
                    <option value="Shared Bike">Shared Bike</option>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label small fw-semibold">From</label>
                <input type="text" class="form-control" name="origin" placeholder="Hostel Block A" required>
            </div>
            <div class="col-md-3">
                <label class="form-label small fw-semibold">To</label>
                <input type="text" class="form-control" name="destination" placeholder="Academic Block" required>
            </div>
            <div class="col-md-3">
                <label class="form-label small fw-semibold">Departure</label>
                <input type="datetime-local" class="form-control" name="slotTime" required>
            </div>
            <div class="col-md-3">
                <label class="form-label small fw-semibold">Distance (km)</label>
                <input type="number" class="form-control" name="distanceKm" step="0.1" min="0.1" value="2.0" required>
            </div>
            <div class="col-md-3">
                <label class="form-label small fw-semibold">Capacity (seats)</label>
                <input type="number" class="form-control" name="capacity" min="1" value="10" required>
            </div>
            <div class="col-md-6 d-flex align-items-end">
                <button type="submit" class="btn btn-primary px-4" data-ripple>
                    <i class="bi bi-plus-circle me-1"></i>Open slot
                </button>
            </div>
        </div>
    </form>
</div>

<div class="card p-4">
    <span class="section-label d-block mb-3"><i class="bi bi-list-ul me-1"></i>All slots</span>
    <div class="table-responsive">
        <table class="table align-middle mb-0">
            <thead>
            <tr>
                <th class="section-label">Route</th>
                <th class="section-label">Vehicle</th>
                <th class="section-label">Departs</th>
                <th class="section-label">Seats</th>
            </tr>
            </thead>
            <tbody data-reveal>
            <c:forEach var="slot" items="${slots}">
                <tr>
                    <td>
                        <c:set var="parts" value="${fn:split(slot.route, '->')}"/>
                        <div class="journey mb-0">
                            <span class="stop">${fn:trim(parts[0])}</span>
                            <span class="track" style="min-width:20px;"></span>
                            <span class="stop">${fn:trim(parts[1])}</span>
                        </div>
                    </td>
                    <td>
                        <i class="bi ${slot.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'} me-1"
                           style="color: var(--forest-400);"></i>${slot.vehicleType}
                    </td>
                    <td><fmt:formatDate value="${slot.slotTime}" pattern="dd MMM, hh:mm a"/></td>
                    <td>
                        <span class="pill ${slot.remainingCapacity le 0 ? 'pill-full' : 'pill-eco'}">
                            ${slot.bookedCount} / ${slot.capacity}
                        </span>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
