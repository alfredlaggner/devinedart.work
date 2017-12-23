<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Shopify_import extends Model
    {
        protected $fillable =
            [
                'product_id',
                'Handle',
                'Title',
                'Body',
                'Vendor',
                'Type',
                'Tags',
                'Published',
                'Option1 Name',
                'Option1 Value',
                'Option2 Name',
                'Option2 Value',
                'Option3 Name',
                'Option3 Value',
                'Variant SKU',
                'Variant Grams',
                'Variant Inventory Tracker',
                'Variant Inventory Quantity',
                'Variant Inventory Policy',
                'Variant Fulfillment Service',
                'Variant Price',
                'Variant Compare at Price',
                'Variant Requires Shipping',
                'Variant Taxable',
                'Variant Barcode',
                'Image Src',
                'Image Position',
                'Image Alt Text',
                'Gift Card',
                'Variant Image',
                'Variant Weight Unit',
                'Variant Tax Code',
                'SEO Title',
                'SEO Description',
                'Collection'
            ];
    }
