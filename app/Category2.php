<?php

namespace App;

use App\Product;
use Illuminate\Database\Eloquent\Model;

class Category2 extends Model
    {
        protected $table = 'category2';

        protected $fillable = [
            'category2_id',
            'name',
            'description',
            'archive',
            'sort',
            'nav',
        ];


        public function prods2()
            {
                return $this->belongsToMany(Product::class,'category2_products','product_id','category2_id')->withTimestamps();
            }
    }