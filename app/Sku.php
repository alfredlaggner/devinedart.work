<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Sku extends Model
{
        protected $table = 'skus';

        protected $fillable = [
            'merchant_sku_id',
            'size',
            'product_id',
            'price',
            'weight',
            'stock',
            'on_web',
            'sort',
            'alt_price',
            'ship_base',
        ];

        public function product()
            {
                return $this->belongsTo('App\Product')->withTimestamps();
            }
}
