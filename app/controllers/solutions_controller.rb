class SolutionsController < ApplicationController
  before_action :set_industry
  
  def show
    @solution = solution_data[@industry]
    
    if @solution.nil?
      redirect_to root_path, alert: "Solution not found"
      return
    end
    
    @features = @solution[:features]
    @benefits = @solution[:benefits]
    @use_cases = @solution[:use_cases]
    @testimonials = @solution[:testimonials]
  end
  
  private
  
  def set_industry
    @industry = params[:industry].to_sym
  end
  
  def solution_data
    {
      finance: {
        title: "Document Processing for Finance",
        description: "Automate financial document processing with AI-powered extraction",
        hero_image: "finance-hero.jpg",
        features: [
          {
            title: "Invoice Processing",
            description: "Extract line items, totals, and vendor details automatically",
            icon: "receipt"
          },
          {
            title: "Bank Statement Analysis",
            description: "Parse transactions and categorize expenses instantly",
            icon: "bank"
          },
          {
            title: "Expense Report Automation",
            description: "Process receipts and expense claims in seconds",
            icon: "calculator"
          }
        ],
        benefits: [
          "Reduce processing time by 90%",
          "Eliminate manual data entry errors",
          "Improve compliance and audit trails",
          "Scale operations without adding staff"
        ],
        use_cases: [
          {
            title: "Accounts Payable Automation",
            description: "Process thousands of invoices daily with 99% accuracy"
          },
          {
            title: "Financial Reconciliation",
            description: "Match transactions across multiple documents automatically"
          },
          {
            title: "Tax Document Processing",
            description: "Extract data from tax forms and supporting documents"
          }
        ],
        testimonials: [
          {
            quote: "Docutiz reduced our invoice processing time from days to minutes.",
            author: "Sarah Chen",
            role: "CFO, TechCorp",
            company_logo: "techcorp-logo.png"
          }
        ]
      },
      healthcare: {
        title: "Healthcare Document Management",
        description: "HIPAA-compliant document processing for healthcare providers",
        hero_image: "healthcare-hero.jpg",
        features: [
          {
            title: "Medical Records Processing",
            description: "Extract patient information while maintaining privacy",
            icon: "medical"
          },
          {
            title: "Insurance Claims Automation",
            description: "Process claims and EOBs with high accuracy",
            icon: "shield"
          },
          {
            title: "Lab Results Digitization",
            description: "Convert paper lab results to structured data",
            icon: "flask"
          }
        ],
        benefits: [
          "HIPAA-compliant processing",
          "Reduce administrative burden",
          "Faster patient service",
          "Improved data accuracy"
        ],
        use_cases: [
          {
            title: "Patient Intake Automation",
            description: "Digitize patient forms and update EHR systems automatically"
          },
          {
            title: "Insurance Verification",
            description: "Extract and verify insurance information from cards and documents"
          },
          {
            title: "Medical Billing Optimization",
            description: "Process medical bills and reduce claim denials"
          }
        ],
        testimonials: [
          {
            quote: "We've cut our document processing time by 85% while maintaining compliance.",
            author: "Dr. Michael Roberts",
            role: "Director, Regional Medical Center",
            company_logo: "rmc-logo.png"
          }
        ]
      },
      legal: {
        title: "Legal Document Intelligence",
        description: "AI-powered document analysis for law firms and legal departments",
        hero_image: "legal-hero.jpg",
        features: [
          {
            title: "Contract Analysis",
            description: "Extract key terms and clauses from contracts",
            icon: "document"
          },
          {
            title: "Discovery Document Processing",
            description: "Process and categorize large volumes of documents",
            icon: "folder"
          },
          {
            title: "Legal Form Extraction",
            description: "Digitize and extract data from legal forms",
            icon: "clipboard"
          }
        ],
        benefits: [
          "Accelerate document review",
          "Reduce billable hours on routine tasks",
          "Improve accuracy in document analysis",
          "Enhanced searchability of documents"
        ],
        use_cases: [
          {
            title: "Due Diligence Automation",
            description: "Process thousands of documents for M&A transactions"
          },
          {
            title: "Contract Management",
            description: "Extract and track key dates, terms, and obligations"
          },
          {
            title: "Litigation Support",
            description: "Organize and analyze case documents efficiently"
          }
        ],
        testimonials: [
          {
            quote: "Docutiz transformed our due diligence process completely.",
            author: "Jennifer Martinez",
            role: "Partner, Martinez & Associates",
            company_logo: "ma-logo.png"
          }
        ]
      },
      retail: {
        title: "Retail Document Automation",
        description: "Streamline retail operations with intelligent document processing",
        hero_image: "retail-hero.jpg",
        features: [
          {
            title: "Purchase Order Processing",
            description: "Extract SKUs, quantities, and pricing automatically",
            icon: "shopping-cart"
          },
          {
            title: "Supplier Invoice Management",
            description: "Process invoices from multiple suppliers seamlessly",
            icon: "truck"
          },
          {
            title: "Receipt Data Extraction",
            description: "Digitize customer receipts for analytics and returns",
            icon: "receipt"
          }
        ],
        benefits: [
          "Faster order processing",
          "Improved inventory accuracy",
          "Better supplier relationships",
          "Enhanced customer service"
        ],
        use_cases: [
          {
            title: "Supply Chain Documentation",
            description: "Process shipping documents and packing lists automatically"
          },
          {
            title: "Returns Processing",
            description: "Extract data from receipts for faster returns"
          },
          {
            title: "Vendor Management",
            description: "Centralize and process vendor documentation"
          }
        ],
        testimonials: [
          {
            quote: "We process 10x more documents with the same team size.",
            author: "David Kim",
            role: "Operations Director, MegaRetail",
            company_logo: "megaretail-logo.png"
          }
        ]
      },
      logistics: {
        title: "Logistics Document Processing",
        description: "Automate shipping and logistics documentation",
        hero_image: "logistics-hero.jpg",
        features: [
          {
            title: "Bill of Lading Processing",
            description: "Extract shipping details and tracking information",
            icon: "ship"
          },
          {
            title: "Customs Documentation",
            description: "Process import/export documents automatically",
            icon: "globe"
          },
          {
            title: "Delivery Confirmation",
            description: "Digitize POD and delivery receipts",
            icon: "check-circle"
          }
        ],
        benefits: [
          "Reduce shipping delays",
          "Improve tracking accuracy",
          "Faster customs clearance",
          "Better visibility across supply chain"
        ],
        use_cases: [
          {
            title: "International Shipping",
            description: "Process customs forms and shipping documents"
          },
          {
            title: "Last-Mile Delivery",
            description: "Digitize proof of delivery documents"
          },
          {
            title: "Freight Management",
            description: "Extract data from freight bills and manifests"
          }
        ],
        testimonials: [
          {
            quote: "Docutiz eliminated our document bottlenecks in shipping.",
            author: "Maria Rodriguez",
            role: "VP Logistics, Global Shipping Co",
            company_logo: "gsc-logo.png"
          }
        ]
      },
      real_estate: {
        title: "Real Estate Document Solutions",
        description: "Digitize and process property documents with AI",
        hero_image: "realestate-hero.jpg",
        features: [
          {
            title: "Lease Agreement Processing",
            description: "Extract terms, dates, and tenant information",
            icon: "home"
          },
          {
            title: "Property Document Management",
            description: "Organize deeds, titles, and property records",
            icon: "building"
          },
          {
            title: "Inspection Report Digitization",
            description: "Convert inspection reports to structured data",
            icon: "clipboard-check"
          }
        ],
        benefits: [
          "Faster transaction processing",
          "Reduced closing times",
          "Better document organization",
          "Improved compliance"
        ],
        use_cases: [
          {
            title: "Property Management",
            description: "Automate lease processing and tenant documentation"
          },
          {
            title: "Real Estate Transactions",
            description: "Process purchase agreements and closing documents"
          },
          {
            title: "Property Maintenance",
            description: "Digitize maintenance records and inspection reports"
          }
        ],
        testimonials: [
          {
            quote: "We close deals 40% faster with Docutiz's document processing.",
            author: "Robert Thompson",
            role: "Broker, Premier Realty",
            company_logo: "premier-logo.png"
          }
        ]
      }
    }
  end
end