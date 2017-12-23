<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Customer_import extends Model
    {
        protected $fillable =
            [
                'First Name',
                'Last Name',
                'Email',
                'Company', 'Address1',
                'Address2',
                'City',
                'Province Code',
                'Province',
                'Code',
                'Country',
                'Country Code',
                'Zip',
                'Phone',
                'Accepts Marketing',
                'Tags',
                'Note',
                'Tax Exempt'
            ];
    }
