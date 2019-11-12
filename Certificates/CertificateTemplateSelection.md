# Create a certificate template for code signing

Steps:
   1. Open the CA management console
   2. Right click on Certificate Templates and choose Manage
   3. Right click on the Code Signing Certificate and choose Dupicate
   4. Modify the NAME and SECURITY allowing someone to enroll 
   5. Click OK on duplicated template
   6. Return to CA Console and right click on Certificate Templates
   7. Click New and select the newly duplicated certificate
   8. Run MMC and snapin Certificates for User certificates
   9. Open Personal -> Certificates 
  10. Right click on Certifiicates -> All Tasks -> Request New Certificate
  11. Click next twice, select CodeSigning Template -> Enroll
  12. Check to see there is only one Code Signing cert in the MMC

