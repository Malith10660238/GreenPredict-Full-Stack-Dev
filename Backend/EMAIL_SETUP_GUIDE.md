# 📧 Email Setup Guide for GreenPredict

## 🚀 Quick Setup (5 minutes)

### Step 1: Create Gmail App Password

1. **Go to Google Account Settings**
   - Visit: https://myaccount.google.com/
   - Click "Security" in the left sidebar

2. **Enable 2-Step Verification** (if not already enabled)
   - Click "2-Step Verification"
   - Follow the setup process

3. **Generate App Password**
   - Go back to Security
   - Click "App passwords"
   - Select "Mail" and "Other (custom name)"
   - Enter "GreenPredict Backend"
   - Copy the 16-character password (like: `abcd efgh ijkl mnop`)

### Step 2: Configure Environment Variables

1. **Create `.env` file in Backend folder**
   ```bash
   # Copy from env_template.txt
   cp env_template.txt .env
   ```

2. **Edit `.env` file with your credentials**
   ```env
   GMAIL_EMAIL=your-email@gmail.com
   GMAIL_APP_PASSWORD=your-16-character-app-password
   ```

### Step 3: Test Email Sending

1. **Start the backend server**
   ```bash
   cd Backend
   python main_fastapi.py
   ```

2. **Register a new user in your Flutter app**
   - The verification email will be sent automatically
   - Check your email inbox (and spam folder)

## 🎯 Features

### ✅ What You Get:
- **Real email sending** via Gmail SMTP
- **Beautiful HTML emails** with GreenPredict branding
- **Fallback system** - if email fails, shows code in console
- **Professional email templates**
- **Automatic retry** for failed emails

### 📧 Email Template Features:
- **Responsive design** - works on all devices
- **GreenPredict branding** with logo and colors
- **Clear verification code** display
- **Security instructions**
- **Professional footer**

## 🔧 Alternative Email Services

### Option 1: SendGrid (Recommended for Production)
```python
# Add to requirements_final.txt
sendgrid==6.10.0

# In email_service.py, replace SMTP with:
import sendgrid
from sendgrid.helpers.mail import Mail

def send_verification_email(self, recipient_email: str, verification_code: str, user_name: str = "User") -> bool:
    sg = sendgrid.SendGridAPIClient(api_key=os.getenv("SENDGRID_API_KEY"))
    message = Mail(
        from_email=self.sender_email,
        to_emails=recipient_email,
        subject="Verify Your GreenPredict Account",
        html_content=self._create_verification_email_html(verification_code, user_name)
    )
    response = sg.send(message)
    return response.status_code == 202
```

### Option 2: AWS SES
```python
# Add to requirements_final.txt
boto3==1.26.137

# In email_service.py:
import boto3

def send_verification_email(self, recipient_email: str, verification_code: str, user_name: str = "User") -> bool:
    client = boto3.client('ses', region_name='us-east-1')
    response = client.send_email(
        Source=self.sender_email,
        Destination={'ToAddresses': [recipient_email]},
        Message={
            'Subject': {'Data': 'Verify Your GreenPredict Account'},
            'Body': {'Html': {'Data': self._create_verification_email_html(verification_code, user_name)}}
        }
    )
    return response['ResponseMetadata']['HTTPStatusCode'] == 200
```

## 🛠️ Troubleshooting

### Common Issues:

1. **"Authentication failed"**
   - Make sure you're using App Password, not regular password
   - Check if 2-Step Verification is enabled

2. **"Connection refused"**
   - Check your internet connection
   - Verify Gmail SMTP settings

3. **Emails going to spam**
   - Add your Gmail to contacts
   - Mark as "Not Spam" in Gmail

4. **"Too many attempts"**
   - Wait 1 hour before trying again
   - Use different Gmail account for testing

### Testing Commands:

```bash
# Test email service directly
python -c "
from email_service import email_service
result = email_service.send_verification_email('test@example.com', '123456', 'Test User')
print('Email sent:', result)
"
```

## 🎉 Success!

Once configured, your users will receive beautiful verification emails like this:

```
Subject: Verify Your GreenPredict Account

🌱 GreenPredict
Welcome to GreenPredict!

Hello John Doe,

Thank you for joining GreenPredict! To complete your registration and start using our platform, please verify your email address.

Your verification code is:
[ 1 2 3 4 5 6 ]

Enter this code in the GreenPredict app to verify your account.

Important:
- This code will expire in 1 hour
- If you didn't create an account with GreenPredict, please ignore this email
- For security, never share this code with anyone

Happy farming! 🌱
The GreenPredict Team
```

## 📞 Support

If you need help:
1. Check the console logs for error messages
2. Verify your `.env` file configuration
3. Test with a simple email first
4. Check Gmail's "Less secure app access" settings

**That's it! Real email sending is now implemented! 🎯**
