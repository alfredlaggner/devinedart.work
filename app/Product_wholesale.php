<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Product_wholesale extends Model
    {
        protected $connection = 'wholesale';
        protected $table = 'products';
        protected $guarded = ['id'];

        protected $fillable = [
            'product_id',
            'name',
            'uri',
            'description',
            'price',
            'old_price',
            'category_id',
            'special',
            'new',
            'order',
            'type',
            'merchant_product_id',
            'preview_description',
            'sort',
            'is_on_web',
            'is_archive',
            'is_ship_charge',
            'tax_group_id',
            'date_modified',
            'special_description',
            'keywords',
            'out_of_stock_message',
            'custom_info_label',
        ];

        public function products()
            {
                $this->hasOne(Product::class);
            }
    }
