<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.PointsDAO" %>
<%@ page import="com.woxsen.greenmobility.model.PointEvent" %>
<%@ page import="com.woxsen.greenmobility.service.PointsService" %>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    String pageTitle = "Rewards";
    int REDEMPTION_COST = PointsService.REDEMPTION_COST;
    request.setAttribute("redemptionCost", REDEMPTION_COST);

    List<PointEvent> events = new PointsDAO().getRecentEvents(loggedInStudent.getStudentId(), 10);
    request.setAttribute("pointEvents", events);

    int remainder = loggedInStudent.getPointsBalance() % REDEMPTION_COST;
    int progressPercent = (int) Math.round((remainder * 100.0) / REDEMPTION_COST);
    request.setAttribute("progressPercent", progressPercent);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/flash.jspf" %>

<h1 class="page-title text-forest mb-1">Rewards</h1>
<p class="text-secondary mb-4">Earn points on every completed ride and streak &mdash; redeem 200 for a free ride voucher.</p>

<div class="row g-3 mb-4">
    <div class="col-lg-4">
        <div class="stat-tile h-100">
            <div class="stat-value">${student.pointsBalance}</div>
            <div class="stat-label">Points balance</div>
            <i class="bi bi-star-fill stat-glyph"></i>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="stat-tile tile-dark h-100">
            <div class="stat-value">${student.freeRideCredits}</div>
            <div class="stat-label">Free ride vouchers</div>
            <i class="bi bi-gift-fill stat-glyph"></i>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="card p-4 h-100 d-flex flex-column justify-content-center">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="section-label">Progress to next voucher</span>
                <span class="small fw-semibold">${student.pointsBalance % redemptionCost} / ${redemptionCost}</span>
            </div>
            <div class="capacity">
                <div class="bar">
                    <div class="fill" data-fill="${progressPercent}"></div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="card p-4 mb-4">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
            <span class="section-label d-block mb-1"><i class="bi bi-gift me-1"></i>Redeem points</span>
            <p class="text-secondary small mb-0">
                Spend ${redemptionCost} points for one free-ride voucher. It's applied automatically
                the next time you book a slot &mdash; still a real seat, no capacity is skipped.
            </p>
        </div>
        <form method="post" action="redeemReward.jsp" data-busy
              onsubmit="return confirm('Redeem ${redemptionCost} points for a free ride voucher?');">
            <c:choose>
                <c:when test="${student.pointsBalance >= redemptionCost}">
                    <button type="submit" class="btn btn-primary px-4" data-ripple>
                        <i class="bi bi-gift me-1"></i>Redeem ${redemptionCost} pts
                    </button>
                </c:when>
                <c:otherwise>
                    <button type="button" class="btn btn-outline-secondary px-4" disabled>
                        Need ${redemptionCost - student.pointsBalance} more pts
                    </button>
                </c:otherwise>
            </c:choose>
        </form>
    </div>
</div>

<div class="card p-4">
    <span class="section-label d-block mb-3"><i class="bi bi-list-columns-reverse me-1"></i>Points ledger</span>
    <c:choose>
        <c:when test="${empty pointEvents}">
            <p class="text-secondary small mb-0">No points activity yet.</p>
        </c:when>
        <c:otherwise>
            <div class="d-flex flex-column gap-2" data-reveal>
                <c:forEach var="e" items="${pointEvents}">
                    <div class="d-flex justify-content-between align-items-center gap-2">
                        <div class="min-w-0">
                            <div class="small fw-semibold text-truncate">${e.reason}</div>
                            <div class="small" style="color: var(--ink-400);">
                                <fmt:formatDate value="${e.createdAt}" pattern="dd MMM, hh:mm a"/>
                            </div>
                        </div>
                        <span class="pill ${e.points ge 0 ? 'pill-eco' : 'pill-full'} flex-shrink-0">
                            ${e.points ge 0 ? '+' : ''}${e.points} pts
                        </span>
                    </div>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
