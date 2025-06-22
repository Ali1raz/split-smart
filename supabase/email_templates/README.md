# Email Templates Setup for Split Smart

This directory contains email templates for the Split Smart application, including password reset and email verification functionality.

## Files

- `password_reset_template.html` - HTML version of the password reset email
- `password_reset_template.txt` - Plain text version of the password reset email
- `email_verification_template.html` - HTML version of the email verification email
- `email_verification_template.txt` - Plain text version of the email verification email
- `README.md` - This file with setup instructions

## Setting up Email Templates in Supabase

### 1. Access Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Email Templates**

### 2. Configure Magic Link Template (Password Reset)

Since we're using `signInWithOtp` for password reset, we need to customize the Magic Link template:

1. In the Email Templates section, find **Magic Link**
2. Click **Edit** to customize the template
3. Replace the default content with the content from `password_reset_template.html`
4. For the plain text version, use the content from `password_reset_template.txt`

### 3. Configure Signup Template (Email Verification)

For email verification during registration:

1. In the Email Templates section, find **Signup**
2. Click **Edit** to customize the template
3. Replace the default content with the content from `email_verification_template.html`
4. For the plain text version, use the content from `email_verification_template.txt`

### 4. Template Variables

Both templates use the following Supabase template variables:

- `{{ .Token }}` - The OTP/verification code sent to the user
- `{{ .Email }}` - The user's email address

### 5. Customize Templates (Optional)

You can customize the templates by:

- Changing the color scheme (currently uses `#6366f1` as primary color)
- Updating the app name and branding
- Modifying the instructions or security notices
- Adding your company logo or contact information

### 6. Test the Templates

1. Go to **Authentication** > **Users**
2. Create a test user or use an existing one
3. Test both the registration flow and forgot password functionality
4. Check that the emails are received with the correct formatting

## Template Features

### Password Reset Template

- **Modern gradient design** for OTP container
- **Step-by-step numbered instructions** with visual indicators
- **Enhanced security warnings** with icons
- **Expiry notice** prominently displayed
- **Professional branding** consistent with app design

### Email Verification Template

- **Welcoming tone** for new users
- **Clear verification process** with numbered steps
- **Benefits explanation** for email verification
- **Security notices** and warnings
- **Consistent styling** with password reset template

## Security Considerations

- The OTP/verification codes expire after 10 minutes (configurable in Supabase settings)
- Users are automatically signed out after password reset
- Templates include security warnings about not sharing codes
- Rate limiting is handled by Supabase to prevent abuse

## Troubleshooting

### Email Not Received

1. Check spam/junk folder
2. Verify email address is correct
3. Check Supabase email settings and quotas
4. Ensure email provider is properly configured

### Template Not Working

1. Verify template syntax is correct
2. Check that template variables are properly formatted
3. Test with a simple template first
4. Check Supabase logs for errors

### OTP/Verification Issues

1. Ensure the code is entered within the time limit
2. Check that the email address matches exactly
3. Verify the code format (6 digits)
4. Check Supabase authentication logs

## Additional Configuration

### Rate Limiting

Configure rate limiting in Supabase to prevent abuse:

1. Go to **Authentication** > **Settings**
2. Adjust rate limiting settings for OTP requests
3. Consider implementing additional client-side rate limiting

### Email Provider

Ensure your email provider is properly configured:

1. Go to **Settings** > **API**
2. Configure SMTP settings if using custom email provider
3. Test email delivery

### Template Customization

For advanced customization:

1. Use inline CSS for better email client compatibility
2. Test templates across different email clients
3. Consider using email testing services
4. Monitor email delivery rates and user engagement

## Support

If you encounter issues with the email templates or authentication functionality, check:

1. Supabase documentation on email templates
2. Authentication logs in Supabase dashboard
3. Flutter app logs for error messages
4. Network connectivity and email delivery status
5. Email client compatibility and rendering issues
