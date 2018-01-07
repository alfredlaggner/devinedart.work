<?php

namespace App;

//use App\Category2;
use App\Category2product;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
        protected $fillable = [
            'product_id',
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
                return $this->hasOne(Category1::class,'category1_id','category1_id' );
            }

        public function cat2()
            {
                return $this->hasOne(Category2::class,'category2_id','category2_id' );
            }

        public function oldcat2()
            {
                return $this->belongsToMany(Category2::class,'category2_product','category2_id','product_id')->withTimestamps();
            }

        public function skus()
            {
                return $this->hasMany(Sku::class,'product_id','product_id');
            }

        public function images()
            {
                return $this->hasMany(Product_image::class,NIL,'product_id');
            }

        public function cw_product()
            {
                return $this->hasOne(Cw_product::class, 'product_id','product_id');
            }



    }
