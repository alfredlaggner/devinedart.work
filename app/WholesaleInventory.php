<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class WholesaleInventory extends Model
{
        protected $connection = 'wholesale';
        protected $table = 'inventory';
        protected $guarded = ['id'];

        protected $fillable = [
            'sku',
            'product_id',
            'price',
            'stock',
            'order',
            'size',
            'weight',
            'on_web',
            'alt_price',
            'ship_base',
        ];

        public function products()
            {
                $this->hasOne(Product::class);
            }
}
