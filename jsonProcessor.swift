import UIKit

//The aim of this script is to create add an objectID to each product, then spit out the json as a string?

//CHECK THE OUTPUT, IN PARTICULAR: Price, ImageURLs, OpeningTimes, and _geoloc

class Product {
    
    var GTIN: Double?
    var objectID: String?
    var brand: String?
    var model: String?
    var desc: String?
    var price: Double?
    var size: [String]?
    var category: String?
    var shopName: String?
    var shopID: String?
    var stockLevel: Int?
    var imageURLs: [String]?
    var _geoloc: [String: AnyObject]?
    var instagramProfile: String?
    var shopPhoneNumber: String?
    var openingTimes: String?
    var productCode: String?
    var meta: [String: String]
    var timeStamp: Int!
    var attributes: [String]?
    
    init?(json: [String: Any]) {
        if json["Brand"] == nil {print("&*^*&**&1")}
        self.brand = json["Brand"] as! String
        self.model = json["Model"] as? String
        self.desc = json["Desc"] as? String
        
        //Price is usually stored as "£xx.xx" in JSON. We need to remove the £, if it has one, and convert to double.
        if json["Price"] == nil {print("&*^*&**&1b")}
        var priceString = json["Price"] as! String
        if priceString.hasPrefix("£") {
            priceString.remove(at: priceString.startIndex)
        }
        let priceDouble = (Double(priceString))!
        self.price = priceDouble
        
        self.size = json["Size"] as? [String]
        self.category = json["Category"] as? String
        self.shopName = json["ShopName"] as? String
        self.shopID = json["ShopID"] as? String
        self.stockLevel = json["StockLevel"] as? Int
        if json["ImageURLs"] == nil {print("&*^*&**&1b \(self.brand)")}
        self.imageURLs = json["ImageURLs"] as? [String]
        if json["_geoloc"] == nil {print("&*^*&**&2")}
        self._geoloc = json["_geoloc"] as! [String: AnyObject]
        self.instagramProfile = json["InstagramProfile"] as? String
        self.shopPhoneNumber = json["ShopPhoneNumber"] as! String
        if json["OpeningTimes"] == nil {print("&*^*&**&3")}
        self.openingTimes = json["OpeningTimes"] as! String
        self.productCode = json["ProductCode"] as? String
        self.objectID = json["objectID"] as? String
        if json["meta"] == nil {print("&*^*&**&3")}
        self.meta = json["meta"] as! [String: String]!
        self.timeStamp = json["Timestamp"] as? Int
        self.attributes = json["Attributes"] as? [String]
        
//
//        print(self.brand,
//              self.model,
//              self.desc,
//              self.price,
//              self.size,
//              self.category,
//              self.shopName,
//              self.shopID,
//              self.stockLevel,
//              self.imageURLs,
//              self._geoloc,
//              self.instagramProfile,
//              self.shopPhoneNumber,
//              self.openingTimes,
//              self.productCode,
//              self.objectID,
//              self.meta
//        )
        
    }
}

//Create Path for the JSON file located in resources
let unprocessedProductJSONPath = Bundle.main.path(forResource: "jsonScrapedFromRetailer", ofType: "json")

//Convert file location (path) to json Data
let preprocessedJSON = try Data(contentsOf: URL(fileURLWithPath: unprocessedProductJSONPath!))

//Parse the data into swift dictionary
var parsedProductsJSONArray = try! JSONSerialization.jsonObject(with: preprocessedJSON, options: .allowFragments) as! [[String: AnyObject]]

//convert the swift dictionary into an array of Products. This step ensures that all columns from excel are correct.
let productsArray = parsedProductsJSONArray.map{Product(json: $0)}

//This will be used to house our outputted json
var jsonString = ""

var arrayOfImageURLs = [String : [String]]()

//This is the hash function that we will use to create the hash value for our objectID
extension String {
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}

//Add a unique objectID for each product. The productID should be composed of the shopID_Category_HV:#HashValue
for product in productsArray {
    
    //Sometimes the product model may be nil if the webscraper only pulled down a brand. This is becuase sometimes the product title on websites is not broken down in the html to the brand and model, but instead the brand and model is incorporated into one element. In this case, the scraper only takes the brand and adds the entire brand + model string as the brand.
    var productModel = ""
    if product?.model != nil {
        productModel = (product?.model)!
    }
    
    //Sometimes productCode may be nil
    var productCode: String? = nil
    if product?.productCode != nil {
        productCode = (product?.productCode)!
    }
    
    //Sometimes Desc may be "", we should convert this to nil
    var productDescription: String?
    if product?.desc == "" {
        productDescription = nil
    } else {
        productDescription = product?.desc
    }
      
    //Create the unique identifier
    let brandHashValue = product?.brand?.djb2hash
    let modelHashValue = productModel.djb2hash
    let categoryHashValue = product?.category?.djb2hash

    let productCodeHashValue: Int?
    if productCode != nil {
        productCodeHashValue = productCode?.djb2hash
    } else {
        productCodeHashValue = "".djb2hash
    }

    if product?.price == nil || brandHashValue == nil || categoryHashValue == nil {print("&*^*&**&4")}
    let priceDouble = product?.price!
    let priceString = String(priceDouble!)
    let priceHashValue = priceString.djb2hash

    let productHashValue = brandHashValue! ^ modelHashValue ^ categoryHashValue! ^ priceHashValue ^ productCodeHashValue!

    let objectID = "\(product!.shopID!)_\(product!.category!)_HV:\(productHashValue)"
    product!.objectID = objectID
    
//    print("Alt: \(productCode)")
//    print("Norm: \(product?.productCode)")
    
    let newProductJSON = [
        
        objectID : [
         
            "Brand" : product!.brand!,
            "Model" : productModel,
            "Price" : product!.price,
            "Size" : product!.size,
            "Category" : product!.category!,
            "ShopName" : product!.shopName!,
            "ImageURLs" : product!.imageURLs!,
            "_geoloc": product!._geoloc!,
            "objectID": objectID,
            "ShopID": product!.shopID!,
            "Desc": productDescription,
            "InstagramProfile": product!.instagramProfile,
            "ShopPhoneNumber": product!.shopPhoneNumber!,
            "OpeningTimes": product!.openingTimes!,
            "ProductCode": productCode,
            "Meta": product!.meta,
            "Timestamp": product!.timeStamp,
            "Attributes": product!.attributes
        
        ]
    ]

    var urls = [String]()
    for url in product!.imageURLs! {
        urls.append(url)
    }

    arrayOfImageURLs[objectID] = urls

    //turn the JSON data into a string, this can be converted to CSV data (string with data separated by comma's), but is also easier to debug. We need to remove double curly brackets, and also get rid of ’ and replace these with '''
    if JSONSerialization.isValidJSONObject(newProductJSON) {

        if let data = try? JSONSerialization.data(withJSONObject: newProductJSON, options: []) {
            let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            let newString = string?.replacingOccurrences(of: "}}", with: "},")

            jsonString += newString!

        }
    }
}

//Do some final editing then the string is finished.
let finalJSONstring = jsonString.replacingOccurrences(of: "},{", with: "},")
let finalFinalJSONstring = finalJSONstring.replacingOccurrences(of: "[{", with: "{")
let finalFinalFinalJSONstring = finalFinalJSONstring.replacingOccurrences(of: "}]", with: "}")

//STEP 1
//print(finalFinalFinalJSONstring)

//URL EXTRACTOR*********************************

var urlData = ""

if JSONSerialization.isValidJSONObject(arrayOfImageURLs) {
    if let data = try? JSONSerialization.data(withJSONObject: arrayOfImageURLs, options: []) {
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        let newString = string?.replacingOccurrences(of: "}}", with: "},")

        urlData += newString!
    }
}

//STEP 2
let processedURLData = urlData.replacingOccurrences(of: "\\", with: "")
print(processedURLData)

