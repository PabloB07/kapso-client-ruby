# WhatsApp 24-Hour Window Policy - Solutions Guide

## The Problem You're Experiencing

**Error Message**: "Meta reported a deli### Long-term**: Design your messaging strategy around the 24h rule

## Kapso.ai Specific Features

Since you're using Kapso.ai, you may have access to:

- **Template Library**: Pre-built approved templates
- **Template Builder**: Easy template creation interface  
- **Auto-Approval**: Faster template approval process
- **Template Analytics**: Usage statistics and delivery rates
- **Bulk Template Management**: Manage multiple templates

Check your Kapso dashboard for:
1. **Available Templates** - Already approved and ready to use
2. **Template Status** - Pending, approved, or rejected templates
3. **Template Builder** - Create new templates without Meta Business Manager

## Why This Existsy error. Re-engagement message Message failed to send because more than 24 hours have passed since the customer last replied to this number."

This is **NOT** a bug in your Ruby SDK - it's a WhatsApp Business API policy.

## Understanding the 24-Hour Rule

WhatsApp Business API has a **conversation window** policy:

### ✅ Within 24 Hours (Free Messaging Window)
- **Trigger**: Customer sends you a message
- **Duration**: 24 hours from their last message
- **Allowed**: ANY message type (text, images, audio, video, documents)
- **No restrictions**: Send as many messages as you want

### ❌ After 24 Hours (Template-Only Window)  
- **Trigger**: 24+ hours since customer's last message
- **Restriction**: ONLY pre-approved template messages allowed
- **Regular messages**: Will be rejected with your error

## Solutions

### Option 1: Use Template Messages (Recommended)

Template messages work anytime and are designed for business communications:

```ruby
# Send a template message (works 24/7)
response = client.messages.send_template(
  phone_number_id: phone_number_id,
  to: "+56912345678",
  template_name: "hello_world",  # Must be pre-approved
  template_language: "en_US"
)
```

### Option 2: Wait for Customer Reply

- Customer sends any message → Opens 24-hour window
- You can then send regular messages for 24 hours

### Option 3: Create Templates via Kapso.ai

✅ **Current Status**: You already have templates in progress!

1. **Kapso Dashboard**: ✅ Connected (Business Account: `your_business_id_account`)
2. **Template Found**: `reply_message (es_MX) - PENDING`
3. **Status**: Waiting for Meta approval (usually 24-48 hours)
4. **Once Approved**: Use `your_template` template for 24/7 messaging
5. **Test Tool**: `ruby scripts/kapso_template_finder.rb`

## Prevention Strategies

### For Customer Service
- Respond within 24 hours of customer messages
- Use templates for follow-ups after 24h
- Set up auto-responses within the window

### For Marketing  
- Always use approved template messages
- Create templates for different campaigns
- Schedule template sends anytime

### For Notifications
- Use templates for order updates, reminders, etc.
- Create templates for common notifications
- Test templates before going live

## Template Message Examples

### Basic Template (No Variables)
```ruby
client.messages.send_template(
  phone_number_id: phone_number_id,
  to: phone_number,
  template_name: "hello_world",
  template_language: "en_US"
)
```

### Template with Variables
```ruby
client.messages.send_template(
  phone_number_id: phone_number_id,
  to: phone_number,
  template_name: "order_confirmation",
  template_language: "en_US",
  components: [
    {
      type: "body",
      parameters: [
        { type: "text", text: "John" },      # Customer name
        { type: "text", text: "12345" }     # Order number
      ]
    }
  ]
)
```

## Next Steps

1. **Immediate**: Use `ruby template_test.rb` to test template messages
2. **Short-term**: Create templates in Meta Business Manager
3. **Long-term**: Design your messaging strategy around the 24h rule

## Why This Exists

WhatsApp enforces this to:
- Prevent spam
- Ensure quality business communications  
- Protect user experience
- Maintain platform integrity

The Ruby SDK is working perfectly - this is just how WhatsApp Business API works! 🚀