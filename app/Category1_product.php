<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Category1_product extends Model
    {
        protected $table = 'category1_product';

        protected $fillable = [
            'product_id',
            'category1_id',
        ];
}
