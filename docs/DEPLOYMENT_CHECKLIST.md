# Deployment Checklist - Rab Booking

Complete checklist for deploying Rab Booking to production.

---

## Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing (56/56)
- [ ] Code coverage > 50%
- [ ] No critical lint warnings
- [ ] Code reviewed and approved
- [ ] All TODOs resolved or documented
- [ ] No debug code or console.logs
- [ ] Performance optimizations applied

### Environment Configuration
- [ ] `.env.production` created with real credentials
- [ ] Supabase production project configured
- [ ] Stripe live mode keys added
- [ ] All API endpoints point to production
- [ ] Analytics enabled (ENABLE_ANALYTICS=true)
- [ ] Crashlytics enabled (ENABLE_CRASHLYTICS=true)
- [ ] Debug tools disabled (ENABLE_DEBUG_TOOLS=false)

### Database
- [ ] Production database created
- [ ] All migrations applied
- [ ] Indexes created (004_performance_indexes.sql)
- [ ] Row Level Security (RLS) policies configured
- [ ] Database backup schedule configured
- [ ] Test data removed from production

### API & Backend
- [ ] Supabase project live and accessible
- [ ] API rate limiting configured
- [ ] CORS settings configured
- [ ] Edge functions deployed
- [ ] Webhook endpoints configured (Stripe)
- [ ] API keys rotated (don't use dev keys)

### Security
- [ ] SSL/TLS certificates configured
- [ ] API keys secured (not in code)
- [ ] Row Level Security enabled
- [ ] Authentication flows tested
- [ ] Payment security verified
- [ ] ProGuard/R8 enabled for Android
- [ ] Code obfuscation enabled

---

## Build Configuration

### Android
- [ ] Release signing configured
- [ ] `key.properties` file created
- [ ] ProGuard rules updated
- [ ] Version code incremented
- [ ] Version name updated (e.g., 1.0.0)
- [ ] Build variants configured (dev, staging, prod)
- [ ] Permissions reviewed and minimized
- [ ] App size optimized (split APKs if needed)

### iOS
- [ ] Bundle ID configured
- [ ] Signing certificates valid
- [ ] Provisioning profiles updated
- [ ] Version number incremented
- [ ] Build number incremented
- [ ] Info.plist reviewed
- [ ] App Transport Security configured
- [ ] Background modes configured (if needed)

### Web
- [ ] Meta tags configured
- [ ] PWA manifest created
- [ ] Service worker configured
- [ ] Favicon added
- [ ] 404 page configured
- [ ] robots.txt configured
- [ ] sitemap.xml created

---

## Testing Checklist

### Functional Testing
- [ ] Login/Registration works
- [ ] Property search works
- [ ] Property details load correctly
- [ ] Booking flow complete end-to-end
- [ ] Payment processing works
- [ ] User profile updates
- [ ] Owner dashboard CRUD operations
- [ ] Image loading optimized
- [ ] Offline mode graceful handling

### Cross-Platform Testing
- [ ] Tested on Android (min SDK 21)
- [ ] Tested on iOS (min iOS 12)
- [ ] Tested on Web (Chrome, Safari, Firefox)
- [ ] Tested on different screen sizes
- [ ] Tested on tablets
- [ ] Landscape orientation works

### Performance Testing
- [ ] App cold start < 3 seconds
- [ ] List scrolling smooth (60fps)
- [ ] Image loading doesn't block UI
- [ ] Search response < 500ms
- [ ] Memory usage < 150MB
- [ ] No memory leaks detected

### Security Testing
- [ ] Authentication bypasses tested
- [ ] Authorization checks validated
- [ ] SQL injection attempts blocked
- [ ] XSS attempts blocked
- [ ] Payment data not stored locally
- [ ] Sensitive data encrypted

---

## Deployment Steps

### Android Deployment
- [ ] Build release APK/AAB
- [ ] Test APK on physical device
- [ ] Upload to Google Play Console
- [ ] Fill store listing (title, description, screenshots)
- [ ] Configure pricing & distribution
- [ ] Submit for review
- [ ] Monitor review status

### iOS Deployment
- [ ] Build release IPA
- [ ] Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] Fill store listing
- [ ] Add screenshots for all devices
- [ ] Configure pricing & availability
- [ ] Submit for review
- [ ] Monitor review status (1-3 days)

### Web Deployment
- [ ] Build web release
- [ ] Test build locally
- [ ] Deploy to Firebase Hosting / Vercel
- [ ] Configure custom domain
- [ ] Verify SSL certificate
- [ ] Test live deployment
- [ ] Configure CDN caching

---

## Post-Deployment Verification

### Immediate Checks (within 1 hour)
- [ ] App downloads successfully
- [ ] App launches without crashes
- [ ] Login flow works
- [ ] Critical features functional
- [ ] Payment processing works
- [ ] Analytics events firing
- [ ] No critical errors in logs

### 24-Hour Monitoring
- [ ] Crash rate < 1%
- [ ] ANR rate < 0.5%
- [ ] API error rate < 5%
- [ ] Payment success rate > 95%
- [ ] User feedback monitored
- [ ] Performance metrics stable

### One-Week Monitoring
- [ ] User retention > 40%
- [ ] No critical bugs reported
- [ ] App store ratings > 4.0
- [ ] Server costs within budget
- [ ] Database performance good
- [ ] No security incidents

---

## Rollback Plan

### Triggers for Rollback
- Crash rate > 5%
- Critical security vulnerability
- Payment processing failures
- Database corruption
- Major feature broken
- User complaints flooding in

### Rollback Steps
1. [ ] Identify issue and severity
2. [ ] Notify team and stakeholders
3. [ ] Execute rollback procedure (see DEPLOYMENT.md)
4. [ ] Verify rollback successful
5. [ ] Communicate with users
6. [ ] Fix issue in development
7. [ ] Re-test and redeploy

---

## Communication Checklist

### Internal Team
- [ ] Deployment scheduled and communicated
- [ ] Team aware of deployment window
- [ ] On-call engineer assigned
- [ ] Rollback plan reviewed
- [ ] Monitoring alerts configured

### External Communication
- [ ] Users notified of maintenance window (if needed)
- [ ] Release notes prepared
- [ ] App store descriptions updated
- [ ] Social media posts scheduled
- [ ] Support team briefed on new features

---

## Monitoring & Analytics

### Firebase Console
- [ ] Crashlytics dashboard configured
- [ ] Performance monitoring enabled
- [ ] Analytics events configured
- [ ] Custom events tracking
- [ ] Audience segmentation setup

### Supabase Dashboard
- [ ] Database monitoring active
- [ ] API usage tracking
- [ ] Auth success rate monitored
- [ ] Storage usage tracked
- [ ] Alerts configured

### Stripe Dashboard
- [ ] Payment webhooks verified
- [ ] Test mode disabled
- [ ] Live mode enabled
- [ ] Refund policy configured
- [ ] Dispute monitoring active

---

## Compliance & Legal

- [ ] Privacy Policy updated and linked
- [ ] Terms of Service updated and linked
- [ ] GDPR compliance verified (if applicable)
- [ ] Cookie consent implemented (web)
- [ ] Data retention policy configured
- [ ] User data export mechanism available
- [ ] User data deletion mechanism available

---

## Documentation

- [ ] DEPLOYMENT.md up to date
- [ ] README.md updated
- [ ] API documentation current
- [ ] Environment variables documented
- [ ] Architecture diagrams updated
- [ ] Troubleshooting guide current
- [ ] User guides published

---

## Final Checks

Before marking deployment complete:

- [ ] All sections of this checklist completed
- [ ] No critical issues found
- [ ] Team sign-off received
- [ ] Stakeholders informed
- [ ] Monitoring in place
- [ ] Support team ready
- [ ] Rollback plan tested
- [ ] Backup taken before deployment

---

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Developer | | | |
| QA Lead | | | |
| Product Owner | | | |
| DevOps Engineer | | | |

---

## Notes

Add deployment-specific notes here:

```
Date: ___________
Version: ___________
Issues encountered:

Resolutions:

Lessons learned:
```

---

## Post-Deployment Actions

- [ ] Deployment retrospective scheduled
- [ ] Lessons learned documented
- [ ] Process improvements identified
- [ ] Next release planning started

---

Last Updated: 2025-01-15
