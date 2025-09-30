#!/usr/bin/env python3
"""
Email Service for GreenPredict
Handles sending verification emails
"""

import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class EmailService:
    def __init__(self):
        # Gmail SMTP configuration
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = os.getenv("GMAIL_EMAIL")  # Your Gmail address
        self.sender_password = os.getenv("GMAIL_APP_PASSWORD")  # Gmail App Password
        
    def send_verification_email(self, recipient_email: str, verification_code: str, user_name: str = "User") -> bool:
        """
        Send email verification code to user
        """
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = "Verify Your GreenPredict Account"
            message["From"] = self.sender_email
            message["To"] = recipient_email
            
            # Create HTML email content
            html_content = self._create_verification_email_html(verification_code, user_name)
            
            # Create plain text version
            text_content = self._create_verification_email_text(verification_code, user_name)
            
            # Attach both versions
            text_part = MIMEText(text_content, "plain")
            html_part = MIMEText(html_content, "html")
            
            message.attach(text_part)
            message.attach(html_part)
            
            # Create secure connection and send email
            context = ssl.create_default_context()
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls(context=context)
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, recipient_email, message.as_string())
            
            print(f"SUCCESS: Verification email sent successfully to: {recipient_email}")
            return True
            
        except Exception as e:
            print(f"ERROR: Failed to send verification email to {recipient_email}: {str(e)}")
            return False
    
    def _create_verification_email_html(self, verification_code: str, user_name: str) -> str:
        """Create HTML email template"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Verify Your GreenPredict Account</title>
            <style>
                body {{
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f4f4f4;
                }}
                .container {{
                    background-color: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 0 10px rgba(0,0,0,0.1);
                }}
                .header {{
                    text-align: center;
                    margin-bottom: 30px;
                }}
                .logo {{
                    color: #4CAF50;
                    font-size: 28px;
                    font-weight: bold;
                    margin-bottom: 10px;
                }}
                .verification-code {{
                    background-color: #4CAF50;
                    color: white;
                    padding: 15px 30px;
                    font-size: 24px;
                    font-weight: bold;
                    text-align: center;
                    border-radius: 5px;
                    margin: 20px 0;
                    letter-spacing: 3px;
                }}
                .footer {{
                    margin-top: 30px;
                    padding-top: 20px;
                    border-top: 1px solid #eee;
                    font-size: 12px;
                    color: #666;
                    text-align: center;
                }}
                .button {{
                    display: inline-block;
                    background-color: #4CAF50;
                    color: white;
                    padding: 12px 25px;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 10px 0;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">🌱 GreenPredict</div>
                    <h2>Welcome to GreenPredict!</h2>
                </div>
                
                <p>Hello {user_name},</p>
                
                <p>Thank you for joining GreenPredict! To complete your registration and start using our platform, please verify your email address.</p>
                
                <p><strong>Your verification code is:</strong></p>
                <div class="verification-code">{verification_code}</div>
                
                <p>Enter this code in the GreenPredict app to verify your account.</p>
                
                <p><strong>Important:</strong></p>
                <ul>
                    <li>This code will expire in 1 hour</li>
                    <li>If you didn't create an account with GreenPredict, please ignore this email</li>
                    <li>For security, never share this code with anyone</li>
                </ul>
                
                <p>If you have any questions, feel free to contact our support team.</p>
                
                <p>Happy farming! 🌱</p>
                <p><strong>The GreenPredict Team</strong></p>
                
                <div class="footer">
                    <p>This email was sent from GreenPredict. If you have any questions, please contact our support team.</p>
                    <p>© 2024 GreenPredict. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def _create_verification_email_text(self, verification_code: str, user_name: str) -> str:
        """Create plain text email template"""
        return f"""
        Welcome to GreenPredict!
        
        Hello {user_name},
        
        Thank you for joining GreenPredict! To complete your registration and start using our platform, please verify your email address.
        
        Your verification code is: {verification_code}
        
        Enter this code in the GreenPredict app to verify your account.
        
        Important:
        - This code will expire in 1 hour
        - If you didn't create an account with GreenPredict, please ignore this email
        - For security, never share this code with anyone
        
        If you have any questions, feel free to contact our support team.
        
        Happy farming! 🌱
        
        The GreenPredict Team
        
        ---
        This email was sent from GreenPredict. If you have any questions, please contact our support team.
        © 2024 GreenPredict. All rights reserved.
        """

# Global email service instance
email_service = EmailService()
