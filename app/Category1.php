<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Category1 extends Model
{
        protected $table = 'category1';
        protected $fillable = [
            'category1_id',
            'name',
            'description',
            'archive',
            'sort',
            'nav',
        ];


        public function prods1()
            {
                return $this->belongsToMany('App\Product','category1_products','product_id','category1_id')->withTimestamps();
            }
}
