<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Product_image extends Model
{
        protected $fillable = [
            'product_id',
            'imagetype_id',
            'image_id',
            'filename',
            'sortorder',
            'caption',
        ];

        public function product()
            {
                return $this->hasOne(Product::class,nil,'product_id');
            }
}
