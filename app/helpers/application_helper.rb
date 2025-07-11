module ApplicationHelper
  include Pagy::Frontend

  def page_title(title = nil)
    title ||= "Docutiz - AI-Powered Document Extraction Platform"
    content_for(:title, title)
  end

  def page_description(description = nil)
    description ||= "Transform unstructured documents into actionable data with AI-powered extraction. Reduce manual data entry by 90% with enterprise-grade accuracy."
    tag.meta(name: "description", content: description)
  end

  def event_description(event)
    case event
    when "document.created"
      "When a new document is uploaded"
    when "document.processed"
      "When document processing is complete"
    when "document.approved"
      "When a document is approved"
    when "document.rejected"
      "When a document is rejected"
    when "extraction.completed"
      "When data extraction succeeds"
    when "extraction.failed"
      "When data extraction fails"
    when "extraction.reviewed"
      "When extraction results are reviewed"
    when "template.created"
      "When a new template is created"
    when "template.updated"
      "When a template is updated"
    when "user.invited"
      "When a team member is invited"
    when "user.joined"
      "When an invited user joins"
    else
      ""
    end
  end
end
