import Foundation

/// Mock 名片数据集合 [DECISION]
/// 仅用于开发预览和逻辑测试，不作为正式 Ground Truth。
struct MockBusinessCards {
    static let tags: [TagRecord] = [
        TagRecord(name: "Client"),
        TagRecord(name: "Vendor"),
        TagRecord(name: "Tech")
    ]
    
    static let samples: [BusinessCardRecord] = [
        // 1. 英文标准名片 [SAMPLE A]
        BusinessCardRecord(
            name: "John Doe",
            company: "Tech Innovators Inc.",
            jobTitle: "Software Architect",
            phones: [
                PhoneEntry(value: "+1-555-010-8888", type: .mobile)
            ],
            emails: ["john.doe@example.com"],
            website: "www.techinnovators.example",
            address: "123 Silicon Valley Blvd, San Jose, CA",
            tagIDs: [tags[0].id, tags[2].id],
            notes: "Met at TechConf 2026."
        ),
        
        // 2. 中英混合名片 [SAMPLE B]
        BusinessCardRecord(
            name: "张伟 (Zhang Wei)",
            company: "全球商贸有限公司 (Global Trade Co., Ltd.)",
            jobTitle: "销售总监 (Sales Director)",
            phones: [
                PhoneEntry(value: "+86 138-0000-0000", type: .mobile)
            ],
            emails: ["wei.zhang@globaltrade.example"],
            website: "www.globaltrade.example.cn",
            address: "北京市朝阳区商务中心区 A 座 88 层",
            tagIDs: [tags[0].id],
            notes: "重要合作伙伴。"
        ),
        
        // 3. 多号码、多邮箱且缺失 Website 的名片 [SAMPLE C - T10 覆盖]
        BusinessCardRecord(
            name: "Alice Smith",
            company: "Reliable Services Group",
            jobTitle: "Operations Manager",
            phones: [
                PhoneEntry(value: "+44 20 7946 0001", type: .mobile),
                PhoneEntry(value: "+44 20 7946 0002", type: .office),
                PhoneEntry(value: "+44 20 7946 0003", type: .fax)
            ],
            emails: [
                "alice.smith@reliable.example",
                "ops@reliable.example"
            ],
            website: nil, // 缺失 Website [T09]
            address: "456 Business Park, London, UK",
            tagIDs: [tags[1].id],
            notes: "包含 Fax 和多个联系方式。"
        )
    ]
}
