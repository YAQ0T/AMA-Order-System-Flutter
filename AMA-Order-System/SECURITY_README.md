# AMA Order System - Network Access Notes

- The stack is now HTTP-only. No certificates or client certs are required.
- Backend binds to `0.0.0.0` on port `6001` by default. Use your Mac’s LAN IP from other devices, e.g. `http://192.168.x.x:6001`.
- Frontend (Flutter web or mobile) should point `API_BASE_URL` to the same HTTP endpoint.
- Ensure your Mac firewall allows inbound connections on 6001 for devices on the same network.

Quick start:
```bash
cd server
PORT=6001 npm start  # runs on 0.0.0.0:6001
```

If a device cannot reach the server:
- Verify phone and Mac are on the same Wi‑Fi/LAN.
- Find the Mac IP with `ipconfig getifaddr en0` (or `ifconfig`), then use `http://<ip>:6001`.
- Check that no VPN or firewall is blocking LAN access.

### Certificate Validity

- **Period**: 10 years
- **Renewal**: Contact IT 90 days before expiration

---

## 📊 Certificate Details

- **CA**: AMA Root CA
- **Organization**: AMA Company
- **Key Size**: 4096-bit RSA
- **Algorithm**: SHA-256
- **Validity**: 3650 days (10 years)

### Server Certificate SANs

- `DNS:localhost`
- `IP:10.10.10.110`
- `IP:213.6.226.163`
- `IP:127.0.0.1`

---

## 🚀 Deployment Checklist

- [ ] Distribute CA certificate to all employees
- [ ] Distribute employee certificate to all employees
- [ ] Verify employees can install certificates
- [ ] Restart backend server
- [ ] Restart frontend server
- [ ] Test access with employee certificates
- [ ] Verify devices without certificates are blocked
- [ ] Monitor server logs for issues

---

## 📞 Support

For assistance:
1. Check documentation above
2. Review troubleshooting sections
3. Contact IT support with:
   - Device type
   - Error message
   - Screenshots

---

**Last Updated**: 2025-11-27  
**Certificate Expiration**: 2035-11-27 (10 years)
