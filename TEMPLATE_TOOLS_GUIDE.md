# 📋 Kapso Template Management Tools

## The 24-Hour Problem & Solution

**Problem**: You're getting "24 hours have passed" errors when sending messages.  
**Solution**: Use template messages - they work anytime, no 24-hour limit!

## 🛠️ Template Tools (Simplified)

### 1. `scripts/kapso_template_finder.rb` - **MAIN TOOL** ⭐
```bash
ruby scripts/kapso_template_finder.rb
```
**Purpose**: Complete template discovery and testing  
**Features**: 
- Fetches your actual created templates from Kapso

### 2. `scripts/test.rb` - Basic Message Testing
```bash  
ruby scripts/test.rb
```
**Purpose**: Test regular message sending  
**Use when**: Testing within 24-hour window  
**Features**:
- Test regular messages 
- Shows 24h error if outside window

## 📋 Setup Instructions

### Step 1: Find Your Business Account ID

1. **Login to Kapso Dashboard**: https://app.kapso.ai/
2. **Navigate to WhatsApp Business section**
3. **Look for**:
   - "Business Account ID"
   - "WABA ID" 
   - Long number (15+ digits)
4. **Add to `.env` file**:
   ```properties
   BUSINESS_ACCOUNT_ID=your_business_account_id_here
   ```

### Step 2: Discover Your Templates

```bash
ruby scripts/kapso_template_finder.rb
```

✅ **Current Status**: Found 1 template `reply_message (es_MX) - PENDING`  
⏳ **Waiting for approval** - Template will work once Meta approves it

### Step 3: Test Templates

```bash
ruby test_specific_template.rb
# Enter template name when prompted
```

## 🎯 Creating Templates in Kapso

### Via Kapso Dashboard:
1. Login to https://app.kapso.ai/
2. Find "WhatsApp Templates" or "Template Builder"
3. Create simple text template:
   - **Name**: `hello_world` or `welcome_message`
   - **Language**: `en_US`  
   - **Category**: `UTILITY` (usually fastest approval)
   - **Content**: "Hello {{1}}, welcome to our service!"

### Template Approval:
- **Pending**: Template submitted, waiting for Meta approval
- **Approved**: Ready to use anytime  
- **Rejected**: Need to fix and resubmit
- **Time**: Usually 24-48 hours for approval

## 🚀 Using Templates in Code

```ruby
# Once your template is approved:
response = client.messages.send_template(
  phone_number_id: "your_phone_number",
  to: "+56912345678", 
  name: "reply_message",      # Your actual template name
  language: "es_MX"           # Your template language
)

# Templates work 24/7 - no time restrictions!
```

## 🔄 Workflow Summary

1. **Check templates**: `ruby scripts/kapso_template_finder.rb`
2. ✅ **Template found**: `reply_message (es_MX) - PENDING`
3. ⏳ **Wait for approval**: Meta is reviewing your template  
4. **Once approved**: Use `reply_message` template for 24/7 messaging

## ❓ Troubleshooting

### "Template not found"
- Template name is wrong
- Template not approved yet
- Language code incorrect

### "24 hours error" (with templates)
- This shouldn't happen with templates
- Contact Kapso support

### "Business Account ID not found"
- Check Kapso dashboard for WABA ID
- Add to .env file
- Contact Kapso support if unclear

## 📞 Support Resources

- **Kapso Dashboard**: https://app.kapso.ai/
- **Kapso Support**: Contact through dashboard
- **WhatsApp Template Policies**: Check Meta Business documentation

---

**Remember**: Templates solve the 24-hour limitation permanently! Regular messages work within 24h of customer reply, templates work anytime. 🎯