<?php

namespace App;

//use App\Category2;
use App\Category2product;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
        protected $fillable = [
            'name',
            'description',
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

        public function cat1()
            {
                return $this->belongsToMany(Category1::class)->withTimestamps();
            }

        public function cat2()
            {
                return $this->belongsToMany(Category2::class)->withTimestamps();
            }

        public function skus()
            {
                return $this->hasMany(Sku::class);
            }

        public function images()
            {
                return $this->hasMany(Product_image::class);
            }

        public function cw_product()
            {
                return $this->hasOne(Cw_product::class, 'product_id');
            }

    }
